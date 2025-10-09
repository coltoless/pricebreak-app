class FlightAlertsController < ApplicationController
  before_action :authenticate_user!, except: [:unsubscribe]
  before_action :set_alert, only: [:show, :pause, :resume, :expire, :destroy, :update_quality]
  before_action :set_user_alerts, only: [:index, :bulk_action]

  # GET /flight_alerts
  def index
    @alerts = @user_alerts.includes(:flight_filter)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(20)

    @alert_stats = calculate_alert_stats
    @recent_activity = get_recent_activity
    @filter_options = get_filter_options

    respond_to do |format|
      format.html
      format.json { render json: { alerts: @alerts, stats: @alert_stats } }
    end
  end

  # GET /flight_alerts/:id
  def show
    @price_history = get_price_history
    @notification_history = @alert.notification_history || []
    @booking_actions = @alert.booking_actions || []
    @quality_metrics = calculate_quality_metrics

    respond_to do |format|
      format.html
      format.json { render json: { alert: @alert, price_history: @price_history } }
    end
  end

  # PATCH /flight_alerts/:id/pause
  def pause
    @alert.pause!
    
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, notice: 'Alert paused successfully' }
      format.json { render json: { success: true, status: @alert.status } }
    end
  end

  # PATCH /flight_alerts/:id/resume
  def resume
    @alert.resume!
    
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, notice: 'Alert resumed successfully' }
      format.json { render json: { success: true, status: @alert.status } }
    end
  end

  # PATCH /flight_alerts/:id/expire
  def expire
    @alert.expire!
    
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, notice: 'Alert expired successfully' }
      format.json { render json: { success: true, status: @alert.status } }
    end
  end

  # DELETE /flight_alerts/:id
  def destroy
    @alert.destroy!
    
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, notice: 'Alert deleted successfully' }
      format.json { render json: { success: true } }
    end
  end

  # PATCH /flight_alerts/:id/update_quality
  def update_quality
    @alert.update_quality_score
    
    respond_to do |format|
      format.html { redirect_to @alert, notice: 'Alert quality updated' }
      format.json { render json: { success: true, quality_score: @alert.alert_quality_score } }
    end
  end

  # POST /flight_alerts/bulk_action
  def bulk_action
    action = params[:action_type]
    alert_ids = params[:alert_ids] || []
    
    case action
    when 'pause'
      bulk_pause_alerts(alert_ids)
    when 'resume'
      bulk_resume_alerts(alert_ids)
    when 'expire'
      bulk_expire_alerts(alert_ids)
    when 'delete'
      bulk_delete_alerts(alert_ids)
    when 'update_quality'
      bulk_update_quality(alert_ids)
    else
      respond_with_error("Invalid action: #{action}")
      return
    end
    
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, notice: "Bulk #{action} completed" }
      format.json { render json: { success: true, action: action, count: alert_ids.count } }
    end
  end

  # GET /flight_alerts/analytics
  def analytics
    @timeframe = params[:timeframe] || '30_days'
    @analytics_data = calculate_analytics_data(@timeframe)
    @performance_metrics = calculate_performance_metrics
    @user_engagement = calculate_user_engagement

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  # GET /flight_alerts/export
  def export
    @alerts = @user_alerts.includes(:flight_filter)
    @format = params[:format] || 'csv'
    
    case @format
    when 'csv'
      send_data generate_csv_export, filename: "pricebreak_alerts_#{Date.current}.csv"
    when 'json'
      send_data generate_json_export, filename: "pricebreak_alerts_#{Date.current}.json"
    else
      redirect_to flight_alerts_path, alert: 'Invalid export format'
    end
  end

  # GET /flight_alerts/unsubscribe/:token
  def unsubscribe
    token = params[:token]
    alert_id = extract_alert_id_from_token(token)
    
    if alert_id
      alert = FlightAlert.find(alert_id)
      alert.pause!
      
      # Send confirmation email
      PriceAlertMailer.unsubscribe_confirmation(alert.flight_filter&.user, alert_id).deliver_now
      
      redirect_to root_path, notice: 'You have been unsubscribed from this alert'
    else
      redirect_to root_path, alert: 'Invalid unsubscribe link'
    end
  end

  # POST /flight_alerts/:id/test_notification
  def test_notification
    # Send a test notification for the alert
    AlertDeliveryJob.perform_later(@alert.id, :all, { test: true })
    
    respond_to do |format|
      format.html { redirect_to @alert, notice: 'Test notification sent' }
      format.json { render json: { success: true, message: 'Test notification sent' } }
    end
  end

  private

  def set_alert
    @alert = current_user.flight_alerts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_with_error('Alert not found')
  end

  def set_user_alerts
    @user_alerts = current_user.flight_alerts.includes(:flight_filter)
  end

  def calculate_alert_stats
    {
      total_alerts: @user_alerts.count,
      active_alerts: @user_alerts.where(status: 'active').count,
      triggered_alerts: @user_alerts.where(status: 'triggered').count,
      paused_alerts: @user_alerts.where(status: 'paused').count,
      expired_alerts: @user_alerts.where(status: 'expired').count,
      total_savings: @user_alerts.where(status: 'triggered').sum(:price_drop_amount),
      average_quality_score: @user_alerts.average(:alert_quality_score) || 0,
      alerts_this_week: @user_alerts.where('created_at > ?', 1.week.ago).count
    }
  end

  def get_recent_activity
    @user_alerts.joins("LEFT JOIN LATERAL jsonb_array_elements(notification_history) AS n ON true")
                .where("n->>'timestamp' > ?", 1.week.ago)
                .order("n->>'timestamp' DESC")
                .limit(10)
                .pluck("n")
  end

  def get_filter_options
    {
      statuses: FlightAlert::STATUSES,
      notification_methods: FlightAlert::NOTIFICATION_METHODS,
      date_ranges: [
        ['Last 7 days', '7_days'],
        ['Last 30 days', '30_days'],
        ['Last 90 days', '90_days'],
        ['All time', 'all_time']
      ]
    }
  end

  def get_price_history
    # This would integrate with actual price history data
    # For now, return mock data
    []
  end

  def calculate_quality_metrics
    {
      current_score: @alert.alert_quality_score,
      trend: calculate_quality_trend,
      factors: analyze_quality_factors,
      recommendations: generate_quality_recommendations
    }
  end

  def calculate_quality_trend
    # Analyze quality score over time
    'improving' # placeholder
  end

  def analyze_quality_factors
    {
      notification_success_rate: calculate_notification_success_rate,
      price_accuracy: calculate_price_accuracy,
      user_engagement: calculate_user_engagement_for_alert,
      data_freshness: calculate_data_freshness
    }
  end

  def generate_quality_recommendations
    recommendations = []
    
    if @alert.alert_quality_score < 0.5
      recommendations << "Consider adjusting your price target"
    end
    
    if @alert.notification_history&.count { |n| n['success'] == false } > 3
      recommendations << "Check your notification settings"
    end
    
    recommendations
  end

  def calculate_notification_success_rate
    return 0 unless @alert.notification_history.present?
    
    total = @alert.notification_history.count
    successful = @alert.notification_history.count { |n| n['success'] == true }
    
    total > 0 ? (successful.to_f / total * 100).round(1) : 0
  end

  def calculate_price_accuracy
    # This would calculate based on actual price data
    95.0 # placeholder
  end

  def calculate_user_engagement_for_alert
    # This would calculate based on user interactions
    75.0 # placeholder
  end

  def calculate_data_freshness
    return 0 unless @alert.last_checked
    
    hours_ago = (Time.current - @alert.last_checked) / 1.hour
    [100 - (hours_ago * 5), 0].max.round(1)
  end

  def bulk_pause_alerts(alert_ids)
    @user_alerts.where(id: alert_ids).update_all(status: 'paused')
  end

  def bulk_resume_alerts(alert_ids)
    @user_alerts.where(id: alert_ids).update_all(status: 'active')
  end

  def bulk_expire_alerts(alert_ids)
    @user_alerts.where(id: alert_ids).update_all(status: 'expired')
  end

  def bulk_delete_alerts(alert_ids)
    @user_alerts.where(id: alert_ids).destroy_all
  end

  def bulk_update_quality(alert_ids)
    @user_alerts.where(id: alert_ids).find_each(&:update_quality_score)
  end

  def calculate_analytics_data(timeframe)
    start_date = case timeframe
                when '7_days' then 7.days.ago
                when '30_days' then 30.days.ago
                when '90_days' then 90.days.ago
                else 1.year.ago
                end

    {
      alerts_created: @user_alerts.where('created_at > ?', start_date).count,
      alerts_triggered: @user_alerts.where('created_at > ?', start_date).where(status: 'triggered').count,
      total_savings: @user_alerts.where('created_at > ?', start_date).where(status: 'triggered').sum(:price_drop_amount),
      average_response_time: calculate_average_response_time(start_date),
      top_routes: calculate_top_routes(start_date),
      notification_effectiveness: calculate_notification_effectiveness(start_date)
    }
  end

  def calculate_performance_metrics
    {
      system_uptime: 99.5,
      average_delivery_time: 2.5, # minutes
      price_accuracy: 98.2,
      user_satisfaction: 4.6 # out of 5
    }
  end

  def calculate_user_engagement
    {
      alerts_created_this_month: @user_alerts.where('created_at > ?', 1.month.ago).count,
      notifications_clicked: calculate_notification_clicks,
      filters_modified: calculate_filters_modified,
      average_session_duration: 8.5 # minutes
    }
  end

  def calculate_average_response_time(start_date)
    # This would calculate based on actual data
    15.2 # minutes
  end

  def calculate_top_routes(start_date)
    @user_alerts.where('created_at > ?', start_date)
                .group(:origin, :destination)
                .count
                .sort_by { |_, count| -count }
                .first(5)
  end

  def calculate_notification_effectiveness(start_date)
    # This would calculate based on actual data
    87.5 # percentage
  end

  def calculate_notification_clicks
    # This would calculate based on actual data
    45 # count
  end

  def calculate_filters_modified
    # This would calculate based on actual data
    12 # count
  end

  def generate_csv_export
    CSV.generate do |csv|
      csv << ['ID', 'Route', 'Status', 'Target Price', 'Current Price', 'Savings', 'Created At', 'Last Checked']
      
      @alerts.each do |alert|
        csv << [
          alert.id,
          alert.route_description,
          alert.status,
          alert.target_price,
          alert.current_price,
          alert.price_drop_amount,
          alert.created_at.strftime('%Y-%m-%d %H:%M:%S'),
          alert.last_checked&.strftime('%Y-%m-%d %H:%M:%S')
        ]
      end
    end
  end

  def generate_json_export
    {
      exported_at: Time.current.iso8601,
      user_id: current_user.id,
      total_alerts: @alerts.count,
      alerts: @alerts.map do |alert|
        {
          id: alert.id,
          route: alert.route_description,
          status: alert.status,
          target_price: alert.target_price,
          current_price: alert.current_price,
          savings: alert.price_drop_amount,
          created_at: alert.created_at.iso8601,
          last_checked: alert.last_checked&.iso8601,
          quality_score: alert.alert_quality_score
        }
      end
    }.to_json
  end

  def extract_alert_id_from_token(token)
    # Extract alert ID from unsubscribe token
    # This is a simple implementation - in production, use proper encryption
    token.split('_')[1] if token.include?('_')
  end

  def respond_with_error(message)
    respond_to do |format|
      format.html { redirect_to flight_alerts_path, alert: message }
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end
end
