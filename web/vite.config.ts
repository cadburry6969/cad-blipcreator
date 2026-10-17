import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // FiveM loads the page from the resource folder, so asset paths must be relative
  base: './',
  build: {
    outDir: 'build',
    emptyOutDir: true,
  },
});
