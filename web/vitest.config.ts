import { defineConfig } from 'vitest/config';
import { cloudflareTest } from '@cloudflare/vitest-plugin';
export default defineConfig({plugins:[cloudflareTest({config:false,miniflare:{compatibilityDate:'2025-09-06',compatibilityFlags:['nodejs_compat'],d1Databases:['DB']}})],test:{include:['tests/**/*.test.ts'],fileParallelism:false,maxWorkers:1}});
