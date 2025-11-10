import React from 'react';
import { createRoot } from 'react-dom/client';
import { FlightPriceFilter } from './components';
import { FlightFilter } from './types/flight-filter';

const Demo: React.FC = () => {
  const handleSaveFilter = (filter: FlightFilter) => {
    console.log('Saving filter:', filter);
    alert(`Filter "${filter.filterName}" saved successfully!`);
  };

  const handlePreviewAlert = (filter: FlightFilter) => {
    console.log('Previewing alert for filter:', filter);
    alert('Alert preview generated! Check the console for details.');
  };

  const handleTestAlert = (filter: FlightFilter) => {
    console.log('Testing alert for filter:', filter);
    alert('Test alert sent! Check your notification methods.');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#8B5CF6] via-[#7C3AED] to-[#6B21A8] py-12">
      <FlightPriceFilter
        onSaveFilter={handleSaveFilter}
        onPreviewAlert={handlePreviewAlert}
        onTestAlert={handleTestAlert}
      />
    </div>
  );
};

// Mount the demo component when the DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('flight-price-filter-demo');
  if (container) {
    const root = createRoot(container);
    root.render(<Demo />);
  }
});

export default Demo;
