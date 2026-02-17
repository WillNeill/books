import { Fyo } from 'fyo';
import { Noun, Verb } from './types';
import { ModelNameEnum } from 'models/types';

declare const __POSTHOG_KEY__: string;
declare const __POSTHOG_HOST__: string;

const ignoreList: string[] = [
  ModelNameEnum.AccountingLedgerEntry,
  ModelNameEnum.StockLedgerEntry,
];

export class TelemetryManager {
  #started = false;
  #posthog: typeof import('posthog-js').default | null = null;
  fyo: Fyo;

  constructor(fyo: Fyo) {
    this.fyo = fyo;
  }

  get started() {
    return this.#started;
  }

  async start(isOpened?: boolean) {
    this.#started = true;
    await this.#initPostHog();

    if (isOpened) {
      this.log(Verb.Opened, 'instance');
    } else {
      this.log(Verb.Resumed, 'instance');
    }
  }

  stop() {
    if (!this.started) {
      return;
    }

    this.log(Verb.Closed, 'instance');
    this.#started = false;
    this.#posthog?.reset();
  }

  log(verb: Verb, noun: Noun, more?: Record<string, unknown>) {
    if (!this.#started && this.fyo.db.isConnected) {
      // eslint-disable-next-line @typescript-eslint/no-floating-promises
      this.start().then(() => this.#capture(verb, noun, more));
      return;
    }

    this.#capture(verb, noun, more);
  }

  async logOpened() {
    await this.#initPostHog();
    this.#capture(Verb.Opened, 'app');
  }

  #capture(verb: Verb, noun: Noun, more?: Record<string, unknown>) {
    if (
      !this.#posthog ||
      this.fyo.store.skipTelemetryLogging ||
      ignoreList.includes(noun)
    ) {
      return;
    }

    if (!this.fyo.singles.SystemSettings?.enableTelemetry) {
      return;
    }

    this.#posthog.capture(verb, { noun, ...more });
  }

  async #initPostHog() {
    if (this.#posthog) {
      return;
    }

    const key =
      typeof __POSTHOG_KEY__ !== 'undefined' ? __POSTHOG_KEY__ : '';
    const host =
      typeof __POSTHOG_HOST__ !== 'undefined' ? __POSTHOG_HOST__ : '';
    if (!key || !host) {
      return;
    }

    const { default: posthog } = await import('posthog-js');
    posthog.init(key, {
      api_host: host,
      autocapture: false,
      capture_pageview: false,
      disable_session_recording: true,
      persistence: 'localStorage',
    });

    const deviceId =
      this.fyo.store.deviceId || (this.fyo.config.get('deviceId') ?? '');
    if (deviceId) {
      posthog.identify(String(deviceId), {
        platform: this.fyo.store.platform,
        country: this.fyo.singles.SystemSettings?.countryCode ?? '',
        language: this.fyo.store.language,
        version: this.fyo.store.appVersion,
      });
    }

    this.#posthog = posthog;
  }
}
