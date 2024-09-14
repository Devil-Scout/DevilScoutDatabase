------------------------------
-- THIS IS A GENERATED FILE --
--  DO NOT MODIFY BY HAND   --
------------------------------

CREATE TYPE "frc_event_type" AS ENUM (
  'off_season',
  'regional',
  'district',
  'district_championship',
  'championship'
);

CREATE TYPE "frc_match_level" AS ENUM (
  'practice',
  'qual',
  'playoff'
);

CREATE OR REPLACE FUNCTION
frc_match_level_2_text(frc_match_level) RETURNS TEXT
AS $$ SELECT $1 $$
STRICT IMMUTABLE LANGUAGE SQL;

CREATE TYPE "frc_alliance" AS ENUM (
  'red',
  'blue'
);

CREATE TABLE "teams" (
  "number" smallint PRIMARY KEY,
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "users" (
  "id" uuid PRIMARY KEY DEFAULT (auth.uid()),
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "team_users" (
  "user_id" uuid PRIMARY KEY,
  "team_num" smallint NOT NULL,
  "added_by" uuid NOT NULL
);

CREATE TABLE "team_requests" (
  "user_id" uuid PRIMARY KEY DEFAULT (auth.uid()),
  "team_num" smallint NOT NULL,
  "requested_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "disabled_users" (
  "user_id" uuid PRIMARY KEY,
  "disabled_by" uuid NOT NULL DEFAULT (auth.uid())
);

CREATE TABLE "permission_types" (
  "id" citext PRIMARY KEY,
  "name" text NOT NULL,
  "description" text NOT NULL
);

CREATE TABLE "permissions" (
  "user_id" uuid NOT NULL,
  "type" citext NOT NULL,
  "granted_by" uuid DEFAULT (auth.uid()),
  PRIMARY KEY ("user_id", "type")
);

CREATE TABLE "frc_seasons" (
  "year" smallint PRIMARY KEY,
  "name" text NOT NULL,
  "team_count" smallint NOT NULL
);

CREATE TABLE "frc_districts" (
  "key" citext PRIMARY KEY,
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "name" text NOT NULL
);

CREATE TABLE "frc_events" (
  "key" citext PRIMARY KEY
    GENERATED ALWAYS AS
      (season || code)
      STORED,
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "type" frc_event_type,
  "name" text NOT NULL,
  "venue" text NOT NULL,
  "address" text NOT NULL,
  "city" text NOT NULL,
  "province" text NOT NULL,
  "country" text NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "website" text
);

CREATE TABLE "frc_district_events" (
  "event_key" citext PRIMARY KEY,
  "district_key" citext NOT NULL
);

CREATE TABLE "frc_teams" (
  "key" citext PRIMARY KEY
    GENERATED ALWAYS AS
      (season || '_' || number)
      STORED,
  "season" smallint NOT NULL,
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "rookie_season" smallint NOT NULL,
  "schools" text[] NOT NULL,
  "sponsors" text[] NOT NULL,
  "city" text NOT NULL,
  "province" text NOT NULL,
  "country" text NOT NULL,
  "website" text
);

CREATE TABLE "frc_district_teams" (
  "team_key" citext PRIMARY KEY,
  "district_key" citext NOT NULL
);

CREATE TABLE "frc_event_teams" (
  "event_key" citext NOT NULL,
  "team_key" citext NOT NULL,
  PRIMARY KEY ("event_key", "team_key")
);

CREATE TABLE "frc_matches" (
  "key" citext PRIMARY KEY
    GENERATED ALWAYS AS
      (event_key || '_' || frc_match_level_2_text(level) || 's' || set || 'm' || number)
      STORED,
  "event_key" citext NOT NULL,
  "level" frc_match_level NOT NULL,
  "set" smallint NOT NULL,
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "scheduled_time" timestamp NOT NULL
);

CREATE TABLE "frc_match_teams" (
  "match_key" citext NOT NULL,
  "team_key" citext NOT NULL,
  "alliance" frc_alliance NOT NULL,
  PRIMARY KEY ("match_key", "team_key")
);

CREATE TABLE "frc_match_results" (
  "match_key" citext PRIMARY KEY,
  "red_score" smallint NOT NULL,
  "blue_score" smallint NOT NULL,
  "red_breakdown" jsonb NOT NULL,
  "blue_breakdown" jsonb NOT NULL,
  "actual_time" timestamp NOT NULL,
  "video_url" text
);

CREATE TABLE "question_types" (
  "id" text PRIMARY KEY
);

CREATE TABLE "categories" (
  "id" text PRIMARY KEY,
  "has_match" bool NOT NULL
);

CREATE TABLE "sections" (
  "season" smallint NOT NULL,
  "category" text NOT NULL,
  "key" text NOT NULL,
  "index" smallint NOT NULL,
  "heading" text NOT NULL,
  PRIMARY KEY ("season", "category", "key")
);

CREATE TABLE "questions" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "season" smallint NOT NULL,
  "category" text NOT NULL,
  "section_key" text NOT NULL,
  "key" text NOT NULL,
  "index" smallint NOT NULL,
  "prompt" text NOT NULL,
  "type" text NOT NULL,
  "config" jsonb NOT NULL DEFAULT '{}'
);

CREATE TABLE "submissions" (
  "id" uuid PRIMARY KEY DEFAULT (gen_random_uuid()),
  "category" text NOT NULL,
  "event_key" citext NOT NULL,
  "match_key" citext,
  "season" smallint NOT NULL,
  "team_key" citext NOT NULL,
  "scouted_by" uuid DEFAULT (auth.uid()),
  "scouted_for" smallint,
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE TABLE "submission_data" (
  "submission_id" uuid NOT NULL,
  "question_id" uuid NOT NULL,
  "value" text NOT NULL,
  PRIMARY KEY ("submission_id", "question_id")
);

CREATE TABLE "flagged" (
  "submission_id" uuid PRIMARY KEY,
  "user_id" uuid NOT NULL DEFAULT (auth.uid()),
  "created_at" timestamptz NOT NULL DEFAULT (now())
);

CREATE INDEX ON "team_users" ("team_num");

CREATE INDEX ON "team_requests" ("team_num");

CREATE UNIQUE INDEX ON "frc_districts" ("season", "code");

CREATE UNIQUE INDEX ON "frc_events" ("season", "code");

CREATE UNIQUE INDEX ON "frc_teams" ("season", "number");

CREATE INDEX ON "frc_teams" ("number");

CREATE INDEX ON "frc_district_teams" ("district_key");

CREATE UNIQUE INDEX ON "frc_matches" ("event_key", "level", "set", "number");

CREATE UNIQUE INDEX ON "sections" ("season", "category", "index");

CREATE UNIQUE INDEX ON "questions" ("season", "category", "key");

CREATE UNIQUE INDEX ON "questions" ("season", "category", "section_key", "index");

CREATE INDEX ON "questions" ("season", "category");

CREATE INDEX ON "flagged" ("user_id");

ALTER TABLE "team_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("added_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("disabled_by") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("type") REFERENCES "permission_types" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("granted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "frc_districts" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_district_events" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_district_events" ADD FOREIGN KEY ("district_key") REFERENCES "frc_districts" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_teams" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_district_teams" ADD FOREIGN KEY ("team_key") REFERENCES "frc_teams" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_district_teams" ADD FOREIGN KEY ("district_key") REFERENCES "frc_districts" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("team_key") REFERENCES "frc_teams" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("team_key") REFERENCES "frc_teams" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_results" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key");

ALTER TABLE "sections" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("season", "category", "section_key") REFERENCES "sections" ("season", "category", "key");

ALTER TABLE "questions" ADD FOREIGN KEY ("type") REFERENCES "question_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("team_key") REFERENCES "frc_teams" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_for") REFERENCES "teams" ("number") ON DELETE SET NULL;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("question_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;

ALTER TABLE "flagged" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "flagged" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

