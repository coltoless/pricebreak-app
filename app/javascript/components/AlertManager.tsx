import React, { useState, useEffect } from 'react';
import { 
  Bell, 
  Plus, 
  Edit, 
  Trash2, 
  Play, 
  Pause, 
  CheckCircle, 
  AlertTriangle, 
  Clock, 
  Mail, 
  MessageSquare, 
  Smartphone, 
  Settings,
  Target,
  DollarSign,
  Calendar,
  MapPin,
  Zap,
  Star,
  Eye,
  BarChart3,
  Info,
  X,
  Save,
  Copy,
  Share2
} from 'lucide-react';
import { FlightFilter } from '../types/flight-filter';

interface PriceAlert {
  id: string;
  name: string;
  route: string;
  targetPrice: number;
  currentPrice: number;
  priceDropPercentage: number;
  status: 'active' | 'paused' | 'triggered' | 'expired';
  created: Date;
  lastTriggered?: Date;
  triggerCount: number;
  notificationMethods: {
    email: boolean;
    sms: boolean;
    push: boolean;
    browser: boolean;
  };
  frequency: 'real-time' | 'hourly' | 'daily' | 'weekly';
  priority: 'low' | 'medium' | 'high' | 'critical';
  confidence: 'low' | 'medium' | 'high';
  description?: string;
}

interface AlertManagerProps {
  filter: FlightFilter;
  className?: string;
}

const AlertManager: React.FC<AlertManagerProps> = ({
  filter,
  className = ""
}) => {
  const [alerts, setAlerts] = useState<PriceAlert[]>([]);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [editingAlert, setEditingAlert] = useState<PriceAlert | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Mock alerts data
  useEffect(() => {
    setIsLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      const mockAlerts: PriceAlert[] = [
        {
          id: '1',
          name: 'Seattle to LAX Deal Alert',
          route: 'SEA → LAX',
          targetPrice: 400,
          currentPrice: 456,
          priceDropPercentage: 20,
          status: 'active',
          created: new Date('2024-01-15'),
          lastTriggered: new Date('2024-01-20'),
          triggerCount: 3,
          notificationMethods: {
            email: true,
            sms: false,
            push: true,
            browser: true
          },
          frequency: 'daily',
          priority: 'high',
          confidence: 'high',
          description: 'Looking for deals under $400 for weekend trips'
        },
        {
          id: '2',
          name: 'Business Class Alert',
          route: 'SEA → LAX',
          targetPrice: 800,
          currentPrice: 1200,
          priceDropPercentage: 15,
          status: 'paused',
          created: new Date('2024-01-10'),
          triggerCount: 0,
          notificationMethods: {
            email: true,
            sms: true,
            push: false,
            browser: false
          },
          frequency: 'hourly',
          priority: 'medium',
          confidence: 'medium',
          description: 'Premium cabin deals for business travel'
        },
        {
          id: '3',
          name: 'Last Minute Deals',
          route: 'SEA → LAX',
          targetPrice: 300,
          currentPrice: 320,
          priceDropPercentage: 25,
          status: 'triggered',
          created: new Date('2024-01-05'),
          lastTriggered: new Date('2024-01-22'),
          triggerCount: 5,
          notificationMethods: {
            email: true,
            sms: true,
            push: true,
            browser: true
          },
          frequency: 'real-time',
          priority: 'critical',
          confidence: 'high',
          description: 'Urgent alerts for last-minute travel deals'
        }
      ];
      
      setAlerts(mockAlerts);
      setIsLoading(false);
    }, 1000);
  }, []);

  const [newAlert, setNewAlert] = useState<Partial<PriceAlert>>({
    name: '',
    targetPrice: filter.targetPrice || 0,
    priceDropPercentage: filter.priceDropPercentage || 20,
    status: 'active',
    notificationMethods: filter.notificationMethods || {
      email: true,
      sms: false,
      push: true,
      browser: true
    },
    frequency: filter.monitorFrequency || 'daily',
    priority: filter.instantAlertPriority || 'high',
    confidence: filter.priceBreakConfidence || 'medium',
    description: ''
  });

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    });
  };

  const getStatusColor = (status: PriceAlert['status']) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'paused':
        return 'bg-yellow-100 text-yellow-800';
      case 'triggered':
        return 'bg-blue-100 text-blue-800';
      case 'expired':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusIcon = (status: PriceAlert['status']) => {
    switch (status) {
      case 'active':
        return <Play className="w-4 h-4" />;
      case 'paused':
        return <Pause className="w-4 h-4" />;
      case 'triggered':
        return <Bell className="w-4 h-4" />;
      case 'expired':
        return <Clock className="w-4 h-4" />;
      default:
        return <Clock className="w-4 h-4" />;
    }
  };

  const getPriorityColor = (priority: PriceAlert['priority']) => {
    switch (priority) {
      case 'critical':
        return 'text-red-600';
      case 'high':
        return 'text-orange-600';
      case 'medium':
        return 'text-blue-600';
      case 'low':
        return 'text-gray-600';
      default:
        return 'text-gray-600';
    }
  };

  const getConfidenceColor = (confidence: PriceAlert['confidence']) => {
    switch (confidence) {
      case 'high':
        return 'text-green-600';
      case 'medium':
        return 'text-amber-600';
      case 'low':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const handleCreateAlert = () => {
    const alert: PriceAlert = {
      id: Date.now().toString(),
      name: newAlert.name || 'New Alert',
      route: `${filter.origin?.name || 'Origin'} → ${filter.destination?.name || 'Destination'}`,
      targetPrice: newAlert.targetPrice || 0,
      currentPrice: 500, // Mock current price
      priceDropPercentage: newAlert.priceDropPercentage || 20,
      status: 'active',
      created: new Date(),
      triggerCount: 0,
      notificationMethods: newAlert.notificationMethods || {
        email: true,
        sms: false,
        push: true,
        browser: true
      },
      frequency: newAlert.frequency || 'daily',
      priority: newAlert.priority || 'high',
      confidence: newAlert.confidence || 'medium',
      description: newAlert.description
    };

    setAlerts(prev => [alert, ...prev]);
    setShowCreateForm(false);
    setNewAlert({
      name: '',
      targetPrice: filter.targetPrice || 0,
      priceDropPercentage: filter.priceDropPercentage || 20,
      status: 'active',
      notificationMethods: {
        email: true,
        sms: false,
        push: true,
        browser: true
      },
      frequency: 'daily',
      priority: 'high',
      confidence: 'medium',
      description: ''
    });
  };

  const handleToggleAlert = (alertId: string) => {
    setAlerts(prev => prev.map(alert => 
      alert.id === alertId 
        ? { ...alert, status: alert.status === 'active' ? 'paused' : 'active' }
        : alert
    ));
  };

  const handleDeleteAlert = (alertId: string) => {
    setAlerts(prev => prev.filter(alert => alert.id !== alertId));
  };

  const handleTestAlert = (alertId: string) => {
    // Simulate test notification
    const alert = alerts.find(a => a.id === alertId);
    if (alert) {
      alert('Test notification sent for: ' + alert.name);
    }
  };

  if (isLoading) {
    return (
      <div className={`space-y-6 ${className}`}>
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-24 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Price Alerts</h3>
          <p className="text-sm text-gray-600">Manage your flight price notifications</p>
        </div>
        
        <button
          onClick={() => setShowCreateForm(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-4 h-4" />
          <span>Create Alert</span>
        </button>
      </div>

      {/* Alert Statistics */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Total Alerts</span>
            <Bell className="w-4 h-4 text-gray-400" />
          </div>
          <div className="text-2xl font-bold text-gray-900">{alerts.length}</div>
        </div>

        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Active</span>
            <CheckCircle className="w-4 h-4 text-green-500" />
          </div>
          <div className="text-2xl font-bold text-green-600">
            {alerts.filter(a => a.status === 'active').length}
          </div>
        </div>

        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Triggered</span>
            <AlertTriangle className="w-4 h-4 text-blue-500" />
          </div>
          <div className="text-2xl font-bold text-blue-600">
            {alerts.filter(a => a.status === 'triggered').length}
          </div>
        </div>

        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Total Notifications</span>
            <MessageSquare className="w-4 h-4 text-gray-400" />
          </div>
          <div className="text-2xl font-bold text-gray-900">
            {alerts.reduce((sum, alert) => sum + alert.triggerCount, 0)}
          </div>
        </div>
      </div>

      {/* Alerts List */}
      <div className="space-y-4">
        {alerts.length === 0 ? (
          <div className="text-center py-12 bg-white border border-gray-200 rounded-lg">
            <Bell className="w-12 h-12 mx-auto mb-4 text-gray-400" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No alerts yet</h3>
            <p className="text-gray-600 mb-4">Create your first price alert to start monitoring flight deals</p>
            <button
              onClick={() => setShowCreateForm(true)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Create Alert
            </button>
          </div>
        ) : (
          alerts.map((alert) => (
            <div key={alert.id} className="bg-white border border-gray-200 rounded-lg p-6">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h4 className="text-lg font-semibold text-gray-900">{alert.name}</h4>
                    <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(alert.status)}`}>
                      {getStatusIcon(alert.status)}
                      {alert.status}
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                    <div>
                      <div className="text-sm text-gray-600">Route</div>
                      <div className="font-medium text-gray-900">{alert.route}</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-600">Target Price</div>
                      <div className="font-medium text-gray-900">{formatPrice(alert.targetPrice)}</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-600">Current Price</div>
                      <div className="font-medium text-gray-900">{formatPrice(alert.currentPrice)}</div>
                    </div>
                  </div>

                  <div className="flex items-center gap-6 text-sm text-gray-600 mb-4">
                    <div className="flex items-center gap-1">
                      <Target className="w-4 h-4" />
                      <span className={`font-medium ${getPriorityColor(alert.priority)}`}>
                        {alert.priority} priority
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Clock className="w-4 h-4" />
                      <span>{alert.frequency}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4" />
                      <span className={`font-medium ${getConfidenceColor(alert.confidence)}`}>
                        {alert.confidence} confidence
                      </span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Bell className="w-4 h-4" />
                      <span>{alert.triggerCount} notifications</span>
                    </div>
                  </div>

                  {alert.description && (
                    <p className="text-sm text-gray-600 mb-4">{alert.description}</p>
                  )}

                  {/* Notification Methods */}
                  <div className="flex items-center gap-4 text-sm">
                    <span className="text-gray-600">Notifications:</span>
                    <div className="flex items-center gap-3">
                      {alert.notificationMethods.email && (
                        <div className="flex items-center gap-1 text-blue-600">
                          <Mail className="w-4 h-4" />
                          <span>Email</span>
                        </div>
                      )}
                      {alert.notificationMethods.sms && (
                        <div className="flex items-center gap-1 text-green-600">
                          <MessageSquare className="w-4 h-4" />
                          <span>SMS</span>
                        </div>
                      )}
                      {alert.notificationMethods.push && (
                        <div className="flex items-center gap-1 text-purple-600">
                          <Smartphone className="w-4 h-4" />
                          <span>Push</span>
                        </div>
                      )}
                      {alert.notificationMethods.browser && (
                        <div className="flex items-center gap-1 text-amber-600">
                          <Bell className="w-4 h-4" />
                          <span>Browser</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {alert.lastTriggered && (
                    <div className="mt-2 text-xs text-gray-500">
                      Last triggered: {formatDate(alert.lastTriggered)}
                    </div>
                  )}
                </div>

                {/* Actions */}
                <div className="flex items-center gap-2 ml-4">
                  <button
                    onClick={() => handleToggleAlert(alert.id)}
                    className={`p-2 rounded-lg transition-colors ${
                      alert.status === 'active' 
                        ? 'bg-yellow-100 text-yellow-600 hover:bg-yellow-200' 
                        : 'bg-green-100 text-green-600 hover:bg-green-200'
                    }`}
                    title={alert.status === 'active' ? 'Pause alert' : 'Activate alert'}
                  >
                    {alert.status === 'active' ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
                  </button>
                  
                  <button
                    onClick={() => handleTestAlert(alert.id)}
                    className="p-2 rounded-lg bg-blue-100 text-blue-600 hover:bg-blue-200 transition-colors"
                    title="Test notification"
                  >
                    <Bell className="w-4 h-4" />
                  </button>
                  
                  <button
                    onClick={() => setEditingAlert(alert)}
                    className="p-2 rounded-lg bg-gray-100 text-gray-600 hover:bg-gray-200 transition-colors"
                    title="Edit alert"
                  >
                    <Edit className="w-4 h-4" />
                  </button>
                  
                  <button
                    onClick={() => handleDeleteAlert(alert.id)}
                    className="p-2 rounded-lg bg-red-100 text-red-600 hover:bg-red-200 transition-colors"
                    title="Delete alert"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Create Alert Modal */}
      {showCreateForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full max-h-[80vh] overflow-hidden">
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h3 className="text-lg font-semibold">Create Price Alert</h3>
              <button
                onClick={() => setShowCreateForm(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>
            
            <div className="p-6 space-y-6 overflow-y-auto max-h-[60vh]">
              {/* Alert Name */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Alert Name</label>
                <input
                  type="text"
                  value={newAlert.name || ''}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="e.g., Weekend SEA-LAX Deals"
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {/* Target Price */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Target Price: {formatPrice(newAlert.targetPrice || 0)}
                </label>
                <input
                  type="range"
                  min="0"
                  max="2000"
                  step="50"
                  value={newAlert.targetPrice || 0}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, targetPrice: parseInt(e.target.value) }))}
                  className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>$0</span>
                  <span>$2000</span>
                </div>
              </div>

              {/* Price Drop Percentage */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Alert when price drops: {newAlert.priceDropPercentage || 20}%
                </label>
                <input
                  type="range"
                  min="5"
                  max="50"
                  step="5"
                  value={newAlert.priceDropPercentage || 20}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, priceDropPercentage: parseInt(e.target.value) }))}
                  className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer slider"
                />
                <div className="flex justify-between text-xs text-gray-500 mt-1">
                  <span>5%</span>
                  <span>50%</span>
                </div>
              </div>

              {/* Priority */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Priority</label>
                <select
                  value={newAlert.priority || 'high'}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, priority: e.target.value as any }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="low">Low - Weekly digest</option>
                  <option value="medium">Medium - Daily updates</option>
                  <option value="high">High - Immediate alerts</option>
                  <option value="critical">Critical - Real-time monitoring</option>
                </select>
              </div>

              {/* Frequency */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Check Frequency</label>
                <select
                  value={newAlert.frequency || 'daily'}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, frequency: e.target.value as any }))}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                >
                  <option value="weekly">Weekly</option>
                  <option value="daily">Daily</option>
                  <option value="hourly">Hourly</option>
                  <option value="real-time">Real-time (Premium)</option>
                </select>
              </div>

              {/* Notification Methods */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Notification Methods</label>
                <div className="grid grid-cols-2 gap-3">
                  {[
                    { key: 'email', label: 'Email', icon: Mail },
                    { key: 'sms', label: 'SMS', icon: MessageSquare },
                    { key: 'push', label: 'Push Notification', icon: Smartphone },
                    { key: 'browser', label: 'Browser Notification', icon: Bell }
                  ].map(({ key, label, icon: Icon }) => (
                    <label key={key} className="flex items-center gap-3 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={newAlert.notificationMethods?.[key as keyof typeof newAlert.notificationMethods] || false}
                        onChange={(e) => setNewAlert(prev => ({ 
                          ...prev, 
                          notificationMethods: { 
                            ...prev.notificationMethods, 
                            [key]: e.target.checked 
                          } 
                        }))}
                        className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                      />
                      <Icon className="w-4 h-4 text-gray-500" />
                      <span className="text-sm text-gray-700">{label}</span>
                    </label>
                  ))}
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Description (Optional)</label>
                <textarea
                  value={newAlert.description || ''}
                  onChange={(e) => setNewAlert(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Add notes about this alert..."
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 p-6 border-t border-gray-200 bg-gray-50">
              <button
                onClick={() => setShowCreateForm(false)}
                className="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateAlert}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2"
              >
                <Save className="w-4 h-4" />
                Create Alert
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default AlertManager;

