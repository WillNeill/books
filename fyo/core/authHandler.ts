import { Fyo } from 'fyo';
import { AuthDemuxConstructor } from './types';

interface AuthConfig {
  serverURL: string;
  backend: string;
  port: number;
}

interface Session {
  user: string;
  token: string;
}

export class AuthHandler {
  #config: AuthConfig;
  #session: Session;
  fyo: Fyo;

  constructor(fyo: Fyo, Demux?: AuthDemuxConstructor) {
    this.fyo = fyo;
    this.#config = {
      serverURL: '',
      backend: 'sqlite',
      port: 8000,
    };

    this.#session = {
      user: '',
      token: '',
    };
  }

  set user(value: string) {
    this.#session.user = value;
  }

  get user(): string {
    return this.#session.user;
  }

  get session(): Readonly<Session> {
    return { ...this.#session };
  }

  get config(): Readonly<AuthConfig> {
    return { ...this.#config };
  }

  init() {
    return null;
  }
}
