// In a real environment, this would call our Supabase backend.
// For the Phase 1/Phase 2 test environment, we mock this by saving to localStorage
// which acts as our 'mock_db' for the web console.

export const loadMockConfig = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const stored = localStorage.getItem('abhyas_config');
      if (stored) {
        resolve(JSON.parse(stored));
      } else {
        resolve({
          "config_version": "0.1.0",
          "matra_default_seconds": 1.0,
          "hold_cap_fraction_of_cht": 0.6,
          "comfort_streak_required_for_step": 5,
          "vishrama_days_per_week": 1,
          "levels": [
            {
              "id": 1,
              "name": "Prarambha",
              "gate": "self",
              "practices": ["breath_awareness", "om_chant", "bhramari", "nadi_shodhana_basic"],
              "ratio_ladder": [[1,0,1,0]],
              "base_count": 4,
              "mudras": ["gyan", "chin", "dhyana"],
              "bandhas": [],
              "pariksha": { "min_sessions": 21 }
            },
            {
              "id": 2,
              "name": "Abhyasa",
              "gate": "streak",
              "practices": ["kapalbhati", "ujjayi", "nadi_shodhana_nasika"],
              "ratio_ladder": [[1,0,1,0],[1,0,2,0]],
              "base_count": 4,
              "kapalbhati": { "strokes_per_min": 60, "strokes_per_round_ladder": [30, 45, 60], "rounds": 3 },
              "mudras": ["nasika", "shanmukhi"],
              "bandhas": [],
              "pariksha": { "min_sessions": 42, "consecutive_days_window": 21 }
            }
          ],
          "weaning": {
            "stage_min_weeks": [3, 3, 3, 3, 0],
            "stage_min_consecutive_sessions": [10, 10, 10, 10, 0],
            "graduation_consecutive_sessions": 3
          }
        });
      }
    }, 500);
  });
};

export const saveMockConfig = async (config: any) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      localStorage.setItem('abhyas_config', JSON.stringify(config));
      console.log('Saved config:', config);
      resolve({ success: true });
    }, 800);
  });
};

// Approval requests Mock API
export const loadUnlockRequests = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const stored = localStorage.getItem('abhyas_unlock_requests');
      if (stored) {
        resolve(JSON.parse(stored));
      } else {
        // Seed some mock requests if empty
        const initialRequests = [
          { id: 'req-1', studentName: 'Ravi Kumar', requestedLevel: 3, recentFlags: [], status: 'pending' },
          { id: 'req-2', studentName: 'Priya Sharma', requestedLevel: 4, recentFlags: ['strain'], status: 'pending' }
        ];
        localStorage.setItem('abhyas_unlock_requests', JSON.stringify(initialRequests));
        resolve(initialRequests);
      }
    }, 300);
  });
};

export const saveUnlockRequests = async (requests: any) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      localStorage.setItem('abhyas_unlock_requests', JSON.stringify(requests));
      resolve({ success: true });
    }, 300);
  });
};
