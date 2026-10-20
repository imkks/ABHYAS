import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import '@testing-library/jest-dom/extend-expect';
import App from './App';

test('renders app elements', () => {
  render(<App />);
  const headerElement = screen.getByText(/Abhyas Teacher Console/i);
  expect(headerElement).toBeDefined();
  expect(headerElement).not.toBeNull();

  const rosterHeader = screen.getByText(/Student Roster/i);
  expect(rosterHeader).toBeDefined();
  expect(rosterHeader).not.toBeNull();

  const editorHeader = screen.getByText(/Practice Configuration Editor/i);
  expect(editorHeader).toBeDefined();
  expect(editorHeader).not.toBeNull();
});
