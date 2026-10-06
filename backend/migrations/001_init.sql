CREATE TABLE users (
  id text PRIMARY KEY,
  name text NOT NULL,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  verified boolean NOT NULL DEFAULT false,
  genres text[] NOT NULL DEFAULT '{}',
  language text NOT NULL DEFAULT 'fa',
  subscription_ends_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- One row per pending code. Only the hash is stored.
CREATE TABLE otp_codes (
  id text PRIMARY KEY,
  email text NOT NULL,
  purpose text NOT NULL CHECK (purpose IN ('signup', 'reset')),
  code_hash text NOT NULL,
  attempts int NOT NULL DEFAULT 0,
  expires_at timestamptz NOT NULL,
  new_password_hash text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX otp_email_idx ON otp_codes (email, purpose);

CREATE TABLE titles (
  id text PRIMARY KEY,
  name_fa text NOT NULL,
  name_en text NOT NULL,
  type text NOT NULL CHECK (type IN ('manga', 'manhwa', 'comic')),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'hidden')),
  genres text[] NOT NULL DEFAULT '{}',
  summary text NOT NULL DEFAULT '',
  author text NOT NULL DEFAULT '',
  views int NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE chapters (
  id text PRIMARY KEY,
  title_id text NOT NULL REFERENCES titles(id) ON DELETE CASCADE,
  number int NOT NULL,
  pages int NOT NULL DEFAULT 0,
  published_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (title_id, number)
);

CREATE TABLE devices (
  user_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  name text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, device_id)
);

CREATE TABLE progress (
  user_id text NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  chapter_id text NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
  page int NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, chapter_id)
);

CREATE TABLE plans (
  id text PRIMARY KEY,
  name text NOT NULL,
  months int NOT NULL,
  -- null until the real prices arrive: shown as "[قیمت]"
  price_toman int
);
