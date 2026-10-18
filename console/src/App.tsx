import React from 'react';
import { StudentList } from './components/StudentList';
import { ApprovalWorkflow } from './components/ApprovalWorkflow';
import { ConfigEditor } from './components/ConfigEditor';

function App() {
  return (
    <div style={{ maxWidth: '1200px', margin: '0 auto', fontFamily: 'sans-serif', paddingBottom: '50px' }}>
      <header style={{ padding: '20px', backgroundColor: '#FF9933', color: 'white', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h1 style={{ margin: 0 }}>Abhyas Teacher Console</h1>
      </header>
      <main style={{ padding: '20px' }}>
        <ApprovalWorkflow />
        <StudentList />
        <ConfigEditor />
      </main>
    </div>
  );
}

export default App;
