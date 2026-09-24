/**
 * CodeQL Analysis Entrypoint & CI Build Utilities
 * This script provides utility functions and an analyzable JavaScript target for CodeQL security scanning.
 */
'use strict';

const fs = require('fs');
const path = require('path');

function validateEnvironment() {
  const rootDir = path.resolve(__dirname, '..');
  const pubspecPath = path.join(rootDir, 'pubspec.yaml');
  
  try {
    if (fs.existsSync(pubspecPath)) {
      const content = fs.readFileSync(pubspecPath, 'utf8');
      return content.length > 0;
    }
  } catch (error) {
    console.error('Environment validation error:', error.message);
  }
  return false;
}

function getAppMetadata() {
  return {
    appName: 'job_platform_mobile',
    platform: 'flutter',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  };
}

module.exports = {
  validateEnvironment,
  getAppMetadata,
};
