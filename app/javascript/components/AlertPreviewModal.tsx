import React from 'react';
import { X, Bell, Mail, MessageSquare, Smartphone, Monitor, Plane, DollarSign, Calendar, TrendingDown } from 'lucide-react';
import { FlightFilter } from '../types/flight-filter';

interface AlertPreviewModalProps {
  filter: FlightFilter;
  isOpen: boolean;
  onClose: () => void;
}

const AlertPreviewModal: React.FC<AlertPreviewModalProps> = ({ filter, isOpen, onClose }) => {
  if (!isOpen) return null;

  // Generate preview content based on filter settings
  const generatePreviewContent = () => {
    const route = filter.origin && filter.destination 
      ? `${filter.origin.iata_code} → ${filter.destination.iata_code}`
      : 'Route not set';
    
    const departureDate = filter.departureDate 
      ? filter.departureDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
      : 'Date not set';
    
    // Mock price for preview (would be actual price in real scenario)
    const mockCurrentPrice = filter.targetPrice * 0.85; // 15% drop for preview
    const savings = filter.targetPrice - mockCurrentPrice;
    const savingsPercentage = ((savings / filter.targetPrice) * 100).toFixed(1);

    return {
      route,
      departureDate,
      targetPrice: filter.targetPrice,
      currentPrice: mockCurrentPrice,
      savings,
      savingsPercentage,
      urgency: savingsPercentage >= 15 ? 'urgent' : savingsPercentage >= 8 ? 'significant' : 'minor'
    };
  };

  const preview = generatePreviewContent();

  const getUrgencyColor = (urgency: string) => {
    switch (urgency) {
      case 'urgent': return 'bg-red-50 border-red-200 text-red-800';
      case 'significant': return 'bg-orange-50 border-orange-200 text-orange-800';
      case 'minor': return 'bg-green-50 border-green-200 text-green-800';
      default: return 'bg-gray-50 border-gray-200 text-gray-800';
    }
  };

  const getUrgencyEmoji = (urgency: string) => {
    switch (urgency) {
      case 'urgent': return '🚨';
      case 'significant': return '🎉';
      case 'minor': return '💰';
      default: return '📱';
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto" aria-labelledby="modal-title" role="dialog" aria-modal="true">
      <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        {/* Background overlay */}
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose}></div>

        {/* Modal panel */}
        <div className="inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-2xl sm:w-full">
          <div className="bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4">
            {/* Header */}
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-2xl font-bold text-gray-900 flex items-center">
                <Bell className="w-6 h-6 mr-2 text-blue-600" />
                Alert Preview
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-500 transition-colors"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Alert Content Preview */}
            <div className="space-y-4">
              {/* Main Alert Card */}
              <div className={`border-2 rounded-xl p-6 ${getUrgencyColor(preview.urgency)}`}>
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center">
                    <span className="text-3xl mr-2">{getUrgencyEmoji(preview.urgency)}</span>
                    <div>
                      <h4 className="text-xl font-bold">
                        Price Drop Alert: {preview.route}
                      </h4>
                      <p className="text-sm opacity-80">
                        {preview.urgency.charAt(0).toUpperCase() + preview.urgency.slice(1)} Priority
                      </p>
                    </div>
                  </div>
                  <TrendingDown className="w-8 h-8" />
                </div>

                <div className="bg-white rounded-lg p-4 mb-4">
                  <div className="grid grid-cols-2 gap-4 mb-4">
                    <div>
                      <div className="text-sm text-gray-600 mb-1">Route</div>
                      <div className="font-semibold text-lg flex items-center">
                        <Plane className="w-4 h-4 mr-1" />
                        {preview.route}
                      </div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-600 mb-1">Departure</div>
                      <div className="font-semibold text-lg flex items-center">
                        <Calendar className="w-4 h-4 mr-1" />
                        {preview.departureDate}
                      </div>
                    </div>
                  </div>

                  <div className="border-t pt-4">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-gray-600">Target Price</span>
                      <span className="text-lg font-semibold line-through text-gray-400">
                        ${preview.targetPrice.toFixed(2)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm text-gray-600">Current Price</span>
                      <span className="text-2xl font-bold text-green-600">
                        ${preview.currentPrice.toFixed(2)}
                      </span>
                    </div>
                    <div className="flex items-center justify-between pt-2 border-t">
                      <span className="font-semibold">You Save</span>
                      <span className="text-xl font-bold text-green-700">
                        ${preview.savings.toFixed(2)} ({preview.savingsPercentage}%)
                      </span>
                    </div>
                  </div>
                </div>

                <div className="bg-white rounded-lg p-3">
                  <p className="text-sm">
                    {preview.urgency === 'urgent' && '🚨 This is a significant price drop! Book quickly as this price may not last long.'}
                    {preview.urgency === 'significant' && '🎉 This is a good deal worth considering. Review and book within 24 hours.'}
                    {preview.urgency === 'minor' && '💰 Small price drop detected. Monitor for better deals.'}
                  </p>
                </div>
              </div>

              {/* Notification Methods Preview */}
              <div className="bg-gray-50 rounded-lg p-4">
                <h5 className="font-semibold text-gray-900 mb-3">Notification Methods</h5>
                <div className="grid grid-cols-2 gap-3">
                  {filter.notificationMethods.email && (
                    <div className="flex items-center bg-white p-3 rounded-lg">
                      <Mail className="w-5 h-5 text-gray-600 mr-2" />
                      <span className="text-sm">Email</span>
                    </div>
                  )}
                  {filter.notificationMethods.sms && (
                    <div className="flex items-center bg-white p-3 rounded-lg">
                      <MessageSquare className="w-5 h-5 text-gray-600 mr-2" />
                      <span className="text-sm">SMS</span>
                    </div>
                  )}
                  {filter.notificationMethods.push && (
                    <div className="flex items-center bg-white p-3 rounded-lg">
                      <Smartphone className="w-5 h-5 text-gray-600 mr-2" />
                      <span className="text-sm">Push</span>
                    </div>
                  )}
                  {filter.notificationMethods.browser && (
                    <div className="flex items-center bg-white p-3 rounded-lg">
                      <Monitor className="w-5 h-5 text-gray-600 mr-2" />
                      <span className="text-sm">Browser</span>
                    </div>
                  )}
                </div>
                {Object.values(filter.notificationMethods).every(v => !v) && (
                  <p className="text-sm text-gray-500 mt-2">No notification methods enabled</p>
                )}
              </div>

              {/* Alert Settings Summary */}
              <div className="bg-blue-50 rounded-lg p-4">
                <h5 className="font-semibold text-blue-900 mb-2">Alert Settings</h5>
                <div className="grid grid-cols-2 gap-2 text-sm text-blue-800">
                  <div>
                    <span className="font-medium">Monitoring:</span> {filter.monitorFrequency.replace('-', ' ')}
                  </div>
                  <div>
                    <span className="font-medium">Urgency:</span> {filter.alertUrgency}
                  </div>
                  <div>
                    <span className="font-medium">Price Drop:</span> {filter.priceDropPercentage}%
                  </div>
                  <div>
                    <span className="font-medium">Detail Level:</span> {filter.alertDetailLevel.replace(/-/g, ' ')}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Footer */}
          <div className="bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse">
            <button
              type="button"
              onClick={onClose}
              className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm"
            >
              Close Preview
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AlertPreviewModal;

