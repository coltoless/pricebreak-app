import React, { useState, useEffect } from 'react';
import { 
  TrendingUp, 
  TrendingDown, 
  Calendar, 
  DollarSign, 
  AlertTriangle,
  CheckCircle,
  Clock,
  Target,
  BarChart3,
  Info,
  Zap,
  Bell,
  Star,
  Eye,
  Download
} from 'lucide-react';

interface PriceDataPoint {
  date: string;
  price: number;
  minPrice: number;
  maxPrice: number;
  averagePrice: number;
  confidence: 'low' | 'medium' | 'high';
  alertTriggered: boolean;
}

interface PriceChartProps {
  route?: string;
  dateRange?: '7d' | '30d' | '90d';
  className?: string;
}

const PriceChart: React.FC<PriceChartProps> = ({
  route = "SEA → LAX",
  dateRange = '30d',
  className = ""
}) => {
  const [selectedRange, setSelectedRange] = useState(dateRange);
  const [priceData, setPriceData] = useState<PriceDataPoint[]>([]);
  const [predictionData, setPredictionData] = useState<PriceDataPoint[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Mock data generation
  useEffect(() => {
    setIsLoading(true);
    
    // Generate mock historical data
    const generateMockData = (days: number, isHistorical = true) => {
      const data: PriceDataPoint[] = [];
      const basePrice = 450;
      const today = new Date();
      
      for (let i = days; i >= 0; i--) {
        const date = new Date(today);
        date.setDate(date.getDate() - (isHistorical ? i : -i));
        
        // Simulate price volatility
        const volatility = 0.15;
        const trend = isHistorical ? 0.02 : -0.01; // Slight upward trend historically, slight downward for prediction
        const randomFactor = (Math.random() - 0.5) * 2;
        
        const price = basePrice * (1 + trend * (days - i) + randomFactor * volatility);
        const minPrice = price * (0.85 + Math.random() * 0.1);
        const maxPrice = price * (1.05 + Math.random() * 0.1);
        
        data.push({
          date: date.toISOString().split('T')[0],
          price: Math.round(price),
          minPrice: Math.round(minPrice),
          maxPrice: Math.round(maxPrice),
          averagePrice: Math.round((minPrice + maxPrice + price) / 3),
          confidence: Math.random() > 0.7 ? 'high' : Math.random() > 0.4 ? 'medium' : 'low',
          alertTriggered: Math.random() > 0.8 && price < basePrice * 0.9
        });
      }
      
      return data;
    };

    const days = selectedRange === '7d' ? 7 : selectedRange === '30d' ? 30 : 90;
    
    setTimeout(() => {
      setPriceData(generateMockData(days, true));
      setPredictionData(generateMockData(7, false)); // 7-day prediction
      setIsLoading(false);
    }, 1000);
  }, [selectedRange]);

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(price);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric' 
    });
  };

  const getCurrentPrice = () => {
    return priceData[priceData.length - 1]?.price || 0;
  };

  const getMinPrice = () => {
    return Math.min(...priceData.map(d => d.minPrice));
  };

  const getMaxPrice = () => {
    return Math.max(...priceData.map(d => d.maxPrice));
  };

  const getPriceChange = () => {
    if (priceData.length < 2) return { amount: 0, percentage: 0, direction: 'stable' };
    
    const current = priceData[priceData.length - 1].price;
    const previous = priceData[priceData.length - 2].price;
    const change = current - previous;
    const percentage = ((change / previous) * 100);
    
    return {
      amount: Math.abs(change),
      percentage: Math.abs(percentage),
      direction: change > 0 ? 'up' : change < 0 ? 'down' : 'stable'
    };
  };

  const getRecommendation = () => {
    const current = getCurrentPrice();
    const min = getMinPrice();
    const recentLow = Math.min(...priceData.slice(-7).map(d => d.minPrice));
    
    if (current <= recentLow * 1.05) {
      return {
        action: 'buy',
        confidence: 'high',
        message: 'Great time to book! Price is near recent low.',
        icon: CheckCircle,
        color: 'text-green-600'
      };
    } else if (current <= recentLow * 1.15) {
      return {
        action: 'consider',
        confidence: 'medium',
        message: 'Good price. Consider booking if dates are firm.',
        icon: Eye,
        color: 'text-amber-600'
      };
    } else {
      return {
        action: 'wait',
        confidence: 'high',
        message: 'Price is elevated. Consider waiting for better deals.',
        icon: Clock,
        color: 'text-red-600'
      };
    }
  };

  const priceChange = getPriceChange();
  const recommendation = getRecommendation();

  if (isLoading) {
    return (
      <div className={`space-y-6 ${className}`}>
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="h-64 bg-gray-200 rounded"></div>
        </div>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${className}`}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Price History & Trends</h3>
          <p className="text-sm text-gray-600">{route} • Last {selectedRange}</p>
        </div>
        
        <div className="flex items-center gap-2">
          {['7d', '30d', '90d'].map((range) => (
            <button
              key={range}
              onClick={() => setSelectedRange(range as any)}
              className={`px-3 py-1 text-sm rounded-lg transition-colors ${
                selectedRange === range
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      {/* Price Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {/* Current Price */}
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Current Price</span>
            <DollarSign className="w-4 h-4 text-gray-400" />
          </div>
          <div className="text-2xl font-bold text-gray-900">{formatPrice(getCurrentPrice())}</div>
        </div>

        {/* Price Change */}
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">24h Change</span>
            {priceChange.direction === 'up' ? (
              <TrendingUp className="w-4 h-4 text-red-500" />
            ) : priceChange.direction === 'down' ? (
              <TrendingDown className="w-4 h-4 text-green-500" />
            ) : (
              <BarChart3 className="w-4 h-4 text-gray-400" />
            )}
          </div>
          <div className={`text-2xl font-bold ${
            priceChange.direction === 'up' ? 'text-red-600' : 
            priceChange.direction === 'down' ? 'text-green-600' : 'text-gray-900'
          }`}>
            {priceChange.direction !== 'stable' && (priceChange.direction === 'up' ? '+' : '-')}
            {formatPrice(priceChange.amount)}
          </div>
          <div className="text-sm text-gray-500">
            {priceChange.percentage.toFixed(1)}%
          </div>
        </div>

        {/* Price Range */}
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Price Range</span>
            <Target className="w-4 h-4 text-gray-400" />
          </div>
          <div className="text-lg font-bold text-gray-900">{formatPrice(getMinPrice())}</div>
          <div className="text-sm text-gray-500">Low: {formatPrice(getMinPrice())}</div>
          <div className="text-sm text-gray-500">High: {formatPrice(getMaxPrice())}</div>
        </div>

        {/* Recommendation */}
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-600">Recommendation</span>
            <recommendation.icon className={`w-4 h-4 ${recommendation.color}`} />
          </div>
          <div className={`text-lg font-bold ${recommendation.color}`}>
            {recommendation.action.toUpperCase()}
          </div>
          <div className="text-xs text-gray-500">{recommendation.message}</div>
        </div>
      </div>

      {/* Chart Area */}
      <div className="bg-white border border-gray-200 rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h4 className="font-medium text-gray-900">Price History</h4>
          <div className="flex items-center gap-4 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
              <span className="text-gray-600">Average Price</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-green-500 rounded-full"></div>
              <span className="text-gray-600">Low Price</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-3 h-3 bg-red-500 rounded-full"></div>
              <span className="text-gray-600">High Price</span>
            </div>
          </div>
        </div>

        {/* Simple Chart Visualization */}
        <div className="h-64 flex items-end justify-between border-b border-l border-gray-200 px-4">
          {priceData.map((point, index) => {
            const height = ((point.price - getMinPrice()) / (getMaxPrice() - getMinPrice())) * 100;
            const isRecent = index >= priceData.length - 7;
            
            return (
              <div key={point.date} className="flex flex-col items-center">
                <div className="flex flex-col items-center relative group">
                  <div
                    className={`w-2 rounded-t ${
                      isRecent ? 'bg-blue-500' : 'bg-gray-300'
                    } transition-all duration-300 hover:bg-blue-600`}
                    style={{ height: `${Math.max(height, 5)}%` }}
                  ></div>
                  
                  {/* Tooltip */}
                  <div className="absolute bottom-full mb-2 opacity-0 group-hover:opacity-100 transition-opacity bg-gray-900 text-white text-xs px-2 py-1 rounded whitespace-nowrap z-10">
                    <div>{formatDate(point.date)}</div>
                    <div>{formatPrice(point.price)}</div>
                  </div>
                </div>
                
                {/* X-axis labels (show every 5th point) */}
                {index % Math.ceil(priceData.length / 8) === 0 && (
                  <div className="text-xs text-gray-500 mt-2 transform -rotate-45 origin-left">
                    {formatDate(point.date)}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Y-axis labels */}
        <div className="flex justify-between text-xs text-gray-500 mt-2 px-4">
          <span>{formatPrice(getMinPrice())}</span>
          <span>{formatPrice(getMaxPrice())}</span>
        </div>
      </div>

      {/* Price Alerts & Predictions */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Price Alerts */}
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="flex items-center gap-2 mb-4">
            <Bell className="w-5 h-5 text-amber-500" />
            <h4 className="font-medium text-gray-900">Price Alerts</h4>
          </div>
          
          <div className="space-y-3">
            {priceData.filter(d => d.alertTriggered).slice(-3).map((point, index) => (
              <div key={index} className="flex items-center gap-3 p-3 bg-amber-50 rounded-lg border border-amber-200">
                <AlertTriangle className="w-4 h-4 text-amber-600 flex-shrink-0" />
                <div className="flex-1">
                  <div className="text-sm font-medium text-amber-900">
                    Price dropped to {formatPrice(point.price)}
                  </div>
                  <div className="text-xs text-amber-700">{formatDate(point.date)}</div>
                </div>
                <div className="text-xs text-amber-600 bg-amber-100 px-2 py-1 rounded">
                  Alert sent
                </div>
              </div>
            ))}
            
            {priceData.filter(d => d.alertTriggered).length === 0 && (
              <div className="text-center py-6 text-gray-500">
                <Bell className="w-8 h-8 mx-auto mb-2 text-gray-400" />
                <p className="text-sm">No alerts triggered in this period</p>
              </div>
            )}
          </div>
        </div>

        {/* Price Predictions */}
        <div className="bg-white border border-gray-200 rounded-lg p-6">
          <div className="flex items-center gap-2 mb-4">
            <Zap className="w-5 h-5 text-purple-500" />
            <h4 className="font-medium text-gray-900">7-Day Forecast</h4>
          </div>
          
          <div className="space-y-3">
            {predictionData.slice(-5).map((point, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-purple-50 rounded-lg border border-purple-200">
                <div>
                  <div className="text-sm font-medium text-purple-900">
                    {formatDate(point.date)}
                  </div>
                  <div className="text-xs text-purple-700">
                    Confidence: {point.confidence}
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-bold text-purple-900">
                    {formatPrice(point.price)}
                  </div>
                  <div className="text-xs text-purple-700">
                    ±{formatPrice(point.maxPrice - point.price)}
                  </div>
                </div>
              </div>
            ))}
          </div>
          
          <div className="mt-4 p-3 bg-gray-50 rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <Info className="w-4 h-4 text-gray-500" />
              <span className="text-sm font-medium text-gray-700">Prediction Accuracy</span>
            </div>
            <div className="text-xs text-gray-600">
              Based on historical patterns and seasonal trends. 
              Accuracy: 78% over the last 30 days.
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex items-center justify-between pt-4 border-t border-gray-200">
        <div className="flex items-center gap-4">
          <button className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
            <Bell className="w-4 h-4" />
            Set Price Alert
          </button>
          <button className="flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors">
            <Download className="w-4 h-4" />
            Export Data
          </button>
        </div>
        
        <div className="text-xs text-gray-500">
          Last updated: {new Date().toLocaleString()}
        </div>
      </div>
    </div>
  );
};

export default PriceChart;

