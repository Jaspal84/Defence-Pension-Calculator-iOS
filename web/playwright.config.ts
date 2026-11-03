import process from 'node:process';
import { defineConfig } from '@playwright/test';
export default defineConfig({testDir:'tests/e2e',fullyParallel:false,use:{baseURL:'http://127.0.0.1:4173',launchOptions:{executablePath:process.env.PENSION_CHROMIUM,args:['--no-sandbox']}},webServer:{command:'npm run preview -- --host 127.0.0.1 --port 4173',url:'http://127.0.0.1:4173',reuseExistingServer:!process.env.CI},reporter:'list'});
