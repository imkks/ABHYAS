import React from 'react';

interface Student {
  id: string;
  name: string;
  level: number;
  weaningStage: number;
  flags: string[];
}

const mockStudents: Student[] = [
  { id: '1', name: 'Arjun Das', level: 2, weaningStage: 1, flags: [] },
  { id: '2', name: 'Priya Sharma', level: 4, weaningStage: 2, flags: ['strain'] },
  { id: '3', name: 'Ravi Kumar', level: 6, weaningStage: 4, flags: [] },
];

export const StudentList: React.FC = () => {
  return (
    <div style={{ padding: '20px', fontFamily: 'sans-serif' }}>
      <h2>Student Roster</h2>
      <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #ccc' }}>
            <th style={{ padding: '8px' }}>Name</th>
            <th style={{ padding: '8px' }}>Sopana (Level)</th>
            <th style={{ padding: '8px' }}>Weaning Stage</th>
            <th style={{ padding: '8px' }}>Flags</th>
            <th style={{ padding: '8px' }}>Actions</th>
          </tr>
        </thead>
        <tbody>
          {mockStudents.map((s) => (
            <tr key={s.id} style={{ borderBottom: '1px solid #eee' }}>
              <td style={{ padding: '8px' }}>{s.name}</td>
              <td style={{ padding: '8px' }}>{s.level}</td>
              <td style={{ padding: '8px' }}>{s.weaningStage}</td>
              <td style={{ padding: '8px' }}>
                {s.flags.length > 0 ? (
                  <span style={{ color: 'red', fontWeight: 'bold' }}>{s.flags.join(', ')}</span>
                ) : (
                  <span style={{ color: 'green' }}>None</span>
                )}
              </td>
              <td style={{ padding: '8px' }}>
                <button style={{ marginRight: '8px' }}>View Details</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};
