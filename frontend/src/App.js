import React, { useEffect, useState } from 'react';

function App() {
  const [status, setStatus] = useState('Loading backend status...');

  useEffect(() => {
    // ⚠️ IMPORTANT: Replace '192.168.X.X' with your DEP SYSTEM'S actual local IP address
    // This allows your laptop (or devices on home wifi) to call the Dep backend.
    const depSystemIP = 'http://10.124.167.126:5000';

    fetch(depSystemIP)
      .then(res => res.text())
      .then(data => setStatus(data))
      .catch(err => setStatus('❌ Error connecting to Dep Backend. Is it running?'));
  }, []);

  return (
    <div style={{ textAlign: 'center', marginTop: '50px', fontFamily: 'Arial' }}>
      <h1>☁️ Hybrid Cloud Control Plane</h1>
      <hr style={{ width: '50%' }} />
      <h3>Backend Connection Status:</h3>
      <p style={{ fontSize: '1.2rem', fontWeight: 'bold', color: '#0070f3' }}>
        {status}
      </p>
    </div>
  );
}

export default App;
