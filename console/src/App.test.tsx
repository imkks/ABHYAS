import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import '@testing-library/jest-dom/extend-expect';
import App from './App';

test('shows the temporary unavailable page', () => {
  render(<App />);
  expect(screen.getByRole('heading', { name: /Teacher Console temporarily unavailable/i })).toBeInTheDocument();
  expect(screen.getByText(/teacher console is paused/i)).toBeInTheDocument();
});
