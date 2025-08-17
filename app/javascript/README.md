# Flight Price Monitoring Filter System

A sophisticated React component for PriceBreak that allows users to set up intelligent flight price alerts with instant price break notifications.

## 🚀 Features

### Core Filter Builder
- **Multi-step form** with progress indicator
- **Route & Dates**: Origin/destination autocomplete, trip types, flexible dates
- **Flight Preferences**: Cabin class, passengers, airlines, stops, preferred times
- **Price Settings**: Target price, budget range, price drop alerts
- **Alert Preferences**: Monitoring frequency, urgency, notification methods

### ⚡ Instant Price Break Alerts
- **Two alert types**:
  - **Exact Match**: Price drops below target AND all criteria match
  - **Flexible Match**: Price drops below target EVEN IF some criteria don't match
- **Flexibility options** for partial matches (airline, stops, times, dates)
- **Priority levels** for instant alerts (normal, high, critical)

### Smart Features
- **Popular routes** quick-select
- **Filter templates** (business, vacation, budget, luxury)
- **Historical price trends** visualization
- **Price break confidence** indicators
- **Alert content previews** with examples
- **Real-time monitoring** warnings

## 🏗️ Architecture

### Components Structure
```
FlightPriceFilter/
├── FlightPriceFilter.tsx          # Main component
├── steps/
│   ├── Step1RouteDates.tsx        # Route & dates configuration
│   ├── Step2FlightPreferences.tsx # Flight preferences
│   ├── Step3PriceSettings.tsx     # Price settings & alerts
│   └── Step4AlertPreferences.tsx  # Alert configuration
├── FilterSummary.tsx              # Comprehensive filter summary
└── types/
    └── flight-filter.ts           # TypeScript interfaces
```

### Data Flow
1. User builds filter through multi-step form
2. Each step validates input and updates filter state
3. Filter data is collected and can be saved/exported
4. Component provides hooks for save, preview, and test actions

## 🎯 Usage

### Basic Implementation
```tsx
import { FlightPriceFilter } from './components';
import { FlightFilter } from './types/flight-filter';

const MyComponent = () => {
  const handleSaveFilter = (filter: FlightFilter) => {
    console.log('Saving filter:', filter);
    // Send to backend, save to database, etc.
  };

  const handlePreviewAlert = (filter: FlightFilter) => {
    console.log('Previewing alert:', filter);
    // Generate alert preview
  };

  const handleTestAlert = (filter: FlightFilter) => {
    console.log('Testing alert:', filter);
    // Send test notification
  };

  return (
    <FlightPriceFilter
      onSaveFilter={handleSaveFilter}
      onPreviewAlert={handlePreviewAlert}
      onTestAlert={handleTestAlert}
    />
  );
};
```

### With Initial Data
```tsx
const initialFilter = {
  origin: { code: 'LAX', name: 'Los Angeles International', city: 'Los Angeles', country: 'USA' },
  destination: { code: 'JFK', name: 'John F. Kennedy International', city: 'New York', country: 'USA' },
  tripType: 'round-trip',
  cabinClass: 'business',
  // ... other properties
};

<FlightPriceFilter
  initialFilter={initialFilter}
  onSaveFilter={handleSaveFilter}
/>
```

## 🔧 Configuration

### Filter Templates
Pre-built templates for common use cases:
- **Business Travel**: Premium cabin, flexible dates, urgent alerts
- **Vacation Planning**: Economy class, flexible options, patient monitoring
- **Last-minute**: Aggressive monitoring, flexible criteria
- **Budget**: Strict price limits, flexible preferences
- **Luxury**: Premium everything, exact matches only

### Customization Options
- **Airport data**: Extend the airports array with your data
- **Airlines**: Modify the airlines list
- **Currencies**: Add/remove supported currencies
- **Time slots**: Customize departure/arrival time preferences
- **Monitoring frequencies**: Adjust available monitoring options

## 📱 Responsive Design

The component is fully responsive and works on:
- **Desktop**: Full layout with sidebar
- **Tablet**: Optimized grid layouts
- **Mobile**: Stacked layout with touch-friendly controls

## 🎨 Styling

Built with Tailwind CSS for:
- **Consistent design** across all components
- **Easy customization** through utility classes
- **Dark/light mode** support ready
- **Accessibility** with proper contrast and focus states

## 🔒 Validation

### Form Validation
- **Required fields**: Origin, destination, departure date, filter name
- **Logical validation**: Return date for round-trips, budget range logic
- **User feedback**: Clear error messages and validation states
- **Step validation**: Users can't proceed without valid data

### Data Integrity
- **Type safety**: Full TypeScript support
- **Input sanitization**: Proper data formatting and validation
- **State management**: Consistent filter state across all steps

## 📊 Data Export

### Filter Object Structure
```typescript
interface FlightFilter {
  // Route & Dates
  origin: Airport | null;
  destination: Airport | null;
  tripType: 'one-way' | 'round-trip' | 'multi-city';
  departureDate: Date | null;
  returnDate: Date | null;
  flexibleDates: boolean;
  dateFlexibility: number;
  
  // Flight Preferences
  cabinClass: 'economy' | 'premium-economy' | 'business' | 'first';
  passengers: { adults: number; children: number; infants: number };
  airlinePreferences: string[];
  maxStops: 'nonstop' | '1-stop' | '2+';
  preferredTimes: { departure: string[]; arrival: string[] };
  
  // Price Settings
  targetPrice: number;
  currency: string;
  instantPriceBreakAlerts: {
    enabled: boolean;
    type: 'exact-match' | 'flexible-match';
    flexibilityOptions: { airline: boolean; stops: boolean; times: boolean; dates: boolean };
  };
  priceDropPercentage: number;
  budgetRange: { min: number; max: number };
  priceBreakConfidence: 'low' | 'medium' | 'high';
  
  // Alert Preferences
  monitorFrequency: 'real-time' | 'hourly' | 'daily' | 'weekly';
  alertUrgency: 'patient' | 'moderate' | 'urgent';
  instantAlertPriority: 'normal' | 'high' | 'critical';
  alertDetailLevel: 'exact-matches-only' | 'include-near-matches';
  notificationMethods: { email: boolean; sms: boolean; push: boolean; browser: boolean };
  
  // Metadata
  filterName: string;
  description: string;
  createdAt: Date;
  isActive: boolean;
}
```

## 🚀 Performance

### Optimization Features
- **Lazy loading**: Components load only when needed
- **Efficient re-renders**: Minimal state updates
- **Debounced inputs**: Reduced API calls for search fields
- **Virtual scrolling**: For large dropdown lists (ready for implementation)

### Monitoring Considerations
- **Real-time alerts**: May increase battery usage
- **Data consumption**: Frequent API calls for live monitoring
- **User preferences**: Respect user's monitoring frequency choices

## 🔮 Future Enhancements

### Planned Features
- **AI-powered suggestions**: Smart filter recommendations
- **Price prediction**: Machine learning price forecasts
- **Social sharing**: Group travel coordination
- **Advanced analytics**: Detailed price trend analysis
- **Integration APIs**: Connect with booking platforms

### Extensibility
- **Plugin system**: Custom filter types
- **Webhook support**: Real-time notifications
- **Multi-language**: Internationalization support
- **Custom themes**: Branded styling options

## 🧪 Testing

### Component Testing
```tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { FlightPriceFilter } from './components';

test('renders flight price filter', () => {
  render(<FlightPriceFilter />);
  expect(screen.getByText('Flight Price Monitoring Filter')).toBeInTheDocument();
});

test('validates required fields', () => {
  render(<FlightPriceFilter />);
  const nextButton = screen.getByText('Next');
  fireEvent.click(nextButton);
  expect(screen.getByText('Origin airport is required')).toBeInTheDocument();
});
```

### Integration Testing
- **Form submission**: Test complete filter creation
- **Data persistence**: Verify filter saving
- **Alert generation**: Test notification systems
- **API integration**: Test backend communication

## 📚 Dependencies

### Required Packages
```json
{
  "react": "^18.0.0",
  "react-dom": "^18.0.0",
  "lucide-react": "^0.263.0"
}
```

### Development Dependencies
```json
{
  "@types/react": "^18.0.0",
  "@types/react-dom": "^18.0.0",
  "typescript": "^4.9.0"
}
```

## 🤝 Contributing

### Development Setup
1. Clone the repository
2. Install dependencies: `npm install`
3. Start development server: `npm run dev`
4. Run tests: `npm test`

### Code Standards
- **TypeScript**: Strict type checking enabled
- **ESLint**: Consistent code style
- **Prettier**: Automatic formatting
- **Husky**: Pre-commit hooks

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

### Common Issues
- **Component not rendering**: Check React version compatibility
- **TypeScript errors**: Ensure all types are properly imported
- **Styling issues**: Verify Tailwind CSS is configured

### Getting Help
- **Documentation**: Check this README and inline comments
- **Issues**: Report bugs on GitHub
- **Discussions**: Ask questions in GitHub Discussions

---

Built with ❤️ for PriceBreak - Making flight price monitoring intelligent and accessible.
