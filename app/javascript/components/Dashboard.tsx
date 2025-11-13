import React, { useState, useEffect } from 'react';
import { 
  Plane, 
  Bell, 
  TrendingUp, 
  TrendingDown, 
  DollarSign,
  Filter,
  AlertTriangle,
  CheckCircle,
  Clock,
  BarChart3,
  Settings,
  Plus,
  Eye,
  Calendar,
  MapPin,
  Target,
  Zap
} from 'lucide-react';
import { FlightFilter } from '../types/flight-filter';

interface DashboardStats {
  total_filters: number;
  active_filters: number;
  inactive_filters: number;
  triggered_alerts: number;
  total_savings: number;
  average_savings: number;
}

interface AlertStats {
  total: number;
  active: number;
  triggered: number;
  paused: number;
  expired: number;
}

interface FlightAlert {
  id: number;
  origin: string;
  destination: string;
  departure_date: string;
  current_price: number | null;
  target_price: number;
  status: string;
  price_drop_percentage: number | null;
  created_at: string;
  flight_filter_id: number | null;
}

interface PriceTrend {
  route: string;
  current_price: number;
  trend: {
    direction: 'up' | 'down' | 'stable' | 'unknown';
    percentage: number;
  };
  data_points: number;
}

interface DashboardProps {
  filters?: any[];
  alerts?: any[];
  stats?: {
    filters?: DashboardStats;
    alerts?: AlertStats;
  };
  price_trends?: Record<string, PriceTrend>;
  onFilterClick?: (filterId: number) => void;
  onAlertClick?: (alertId: number) => void;
  onCreateFilter?: () => void;
}

const Dashboard: React.FC<DashboardProps> = ({
  filters = [],
  alerts = [],
  stats = {},
  price_trends = {},
  onFilterClick,
  onAlertClick,
  onCreateFilter
}) => {
  const [isLoading, setIsLoading] = useState(false);

  const filterStats = stats.filters || {
    total_filters: 0,
    active_filters: 0,
    inactive_filters: 0,
    triggered_alerts: 0,
    total_savings: 0,
    average_savings: 0
  };

  const alertStats = stats.alerts || {
    total: 0,
    active: 0,
    triggered: 0,
    paused: 0,
    expired: 0
  };

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      year: 'numeric'
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Stats Cards */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4 mb-8">
        {/* Total Filters */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Filter className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Filters</dt>
                  <dd className="text-lg font-medium text-gray-900">{filterStats.total_filters}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {/* Active Filters */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <CheckCircle className="h-6 w-6 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Active Filters</dt>
                  <dd className="text-lg font-medium text-gray-900">{filterStats.active_filters}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {/* Triggered Alerts */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Bell className="h-6 w-6 text-yellow-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Triggered Alerts</dt>
                  <dd className="text-lg font-medium text-gray-900">{alertStats.triggered}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        {/* Total Savings */}
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <DollarSign className="h-6 w-6 text-green-500" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">Total Savings</dt>
                  <dd className="text-lg font-medium text-gray-900">{formatPrice(filterStats.total_savings)}</dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Filters */}
        <div className="lg:col-span-2">
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-medium text-gray-900">Recent Flight Filters</h3>
                {onCreateFilter && (
                  <button
                    onClick={onCreateFilter}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    <Plus className="h-4 w-4 mr-1" />
                    New Filter
                  </button>
                )}
              </div>

              {filters.length > 0 ? (
                <div className="space-y-4">
                  {filters.map((filter: any) => (
                    <div
                      key={filter.id}
                      className="border rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
                      onClick={() => onFilterClick && onFilterClick(filter.id)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center space-x-2 mb-2">
                            <h4 className="text-sm font-medium text-gray-900">{filter.name}</h4>
                            <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                              filter.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                            }`}>
                              {filter.is_active ? 'Active' : 'Inactive'}
                            </span>
                          </div>
                          <p className="text-xs text-gray-500 mb-2">{filter.route}</p>
                          <div className="flex items-center space-x-4 text-xs text-gray-500">
                            <span>{filter.trip_type}</span>
                            {filter.alerts_count > 0 && (
                              <>
                                <span>•</span>
                                <span>{filter.alerts_count} alerts</span>
                              </>
                            )}
                          </div>
                        </div>
                        <Eye className="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-12">
                  <Filter className="mx-auto h-12 w-12 text-gray-400" />
                  <h3 className="mt-2 text-sm font-medium text-gray-900">No filters</h3>
                  <p className="mt-1 text-sm text-gray-500">Get started by creating your first flight filter.</p>
                  {onCreateFilter && (
                    <div className="mt-6">
                      <button
                        onClick={onCreateFilter}
                        className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                      >
                        <Plus className="h-4 w-4 mr-2" />
                        Create Filter
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Recent Alerts & Quick Actions */}
        <div className="space-y-6">
          {/* Recent Alerts */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-medium text-gray-900">Recent Alerts</h3>
              </div>

              {alerts.length > 0 ? (
                <div className="space-y-3">
                  {alerts.slice(0, 5).map((alert: any) => (
                    <div
                      key={alert.id}
                      className={`border-l-4 pl-3 py-2 cursor-pointer ${
                        alert.status === 'triggered' ? 'border-green-500' :
                        alert.status === 'active' ? 'border-blue-500' :
                        'border-gray-300'
                      }`}
                      onClick={() => onAlertClick && onAlertClick(alert.id)}
                    >
                      <p className="text-sm font-medium text-gray-900">
                        {alert.origin} → {alert.destination}
                      </p>
                      <p className="text-xs text-gray-500">
                        {alert.status}
                        {alert.status === 'triggered' && alert.current_price && (
                          <span> - {formatPrice(alert.current_price)}</span>
                        )}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-gray-500">No alerts yet</p>
              )}
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Quick Actions</h3>
              <div className="space-y-3">
                {onCreateFilter && (
                  <button
                    onClick={onCreateFilter}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md text-sm font-medium text-center block"
                  >
                    Create New Filter
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Price Trends */}
      {Object.keys(price_trends).length > 0 && (
        <div className="mt-6 bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Price Trends</h3>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {Object.entries(price_trends).map(([route, data]: [string, any]) => (
                <div key={route} className="border rounded-lg p-4">
                  <h4 className="text-sm font-medium text-gray-900 mb-2">{route}</h4>
                  {data.trend.direction === 'down' && (
                    <p className="text-green-600 text-sm flex items-center">
                      <TrendingDown className="h-4 w-4 mr-1" />
                      {data.trend.percentage}% lower
                    </p>
                  )}
                  {data.trend.direction === 'up' && (
                    <p className="text-red-600 text-sm flex items-center">
                      <TrendingUp className="h-4 w-4 mr-1" />
                      {data.trend.percentage}% higher
                    </p>
                  )}
                  {data.trend.direction === 'stable' && (
                    <p className="text-gray-600 text-sm">→ Stable</p>
                  )}
                  <p className="text-xs text-gray-500 mt-1">
                    Current: {formatPrice(data.current_price)}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Dashboard;

