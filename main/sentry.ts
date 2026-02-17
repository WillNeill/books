import { app } from 'electron';
import * as Sentry from '@sentry/electron/main';

declare const __SENTRY_DSN__: string;

export function initSentryMain() {
  const dsn = typeof __SENTRY_DSN__ !== 'undefined' ? __SENTRY_DSN__ : '';
  if (!dsn || !app.isPackaged) {
    return;
  }

  Sentry.init({ dsn });
}
