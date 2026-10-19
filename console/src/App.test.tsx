import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders app elements', () => {
  render(<App />);
  const headerElement = screen.getByText(/Abhyas Teacher Console/i);
  expect(headerElement).toBeInTheDocument();

  const rosterHeader = screen.getByText(/Student Roster/i);
  expect(rosterHeader).toBeInTheDocument();

  const editorHeader = screen.getByText(/Practice Configuration Editor/i);
  expect(editorHeader).toBeInTheDocument();
});
