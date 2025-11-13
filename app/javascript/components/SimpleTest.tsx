import React, { useState } from 'react';

const SimpleTest: React.FC = () => {
  const [inputValue, setInputValue] = useState('');
  const [clickCount, setClickCount] = useState(0);

  return (
    <div style={{ padding: '20px', border: '2px solid #10b981', borderRadius: '8px', backgroundColor: '#ecfdf5' }}>
      <h2 style={{ color: '#065f46', marginBottom: '16px' }}>✅ React Component is Working!</h2>
      
      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '8px', color: '#065f46' }}>
          Test Input (type something):
        </label>
        <input
          type="text"
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          placeholder="Type here to test interactivity..."
          style={{
            width: '100%',
            padding: '8px 12px',
            border: '1px solid #10b981',
            borderRadius: '4px',
            fontSize: '16px'
          }}
        />
        <p style={{ marginTop: '8px', color: '#047857' }}>
          You typed: <strong>{inputValue || '(nothing)'}</strong>
        </p>
      </div>

      <div style={{ marginBottom: '16px' }}>
        <button
          onClick={() => setClickCount(clickCount + 1)}
          style={{
            backgroundColor: '#10b981',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '16px'
          }}
        >
          Click Me (Count: {clickCount})
        </button>
      </div>

      <div style={{ marginBottom: '16px' }}>
        <label style={{ display: 'block', marginBottom: '8px', color: '#065f46' }}>
          Test Date Input:
        </label>
        <input
          type="date"
          onChange={(e) => console.log('Date selected:', e.target.value)}
          style={{
            padding: '8px 12px',
            border: '1px solid #10b981',
            borderRadius: '4px',
            fontSize: '16px'
          }}
        />
      </div>

      <p style={{ color: '#047857', fontSize: '14px', marginTop: '16px' }}>
        If you can see this and interact with the inputs/buttons above, React is working correctly!
      </p>
    </div>
  );
};

export default SimpleTest;






