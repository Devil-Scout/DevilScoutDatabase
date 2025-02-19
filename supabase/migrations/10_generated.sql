------------------------------
-- THIS IS A GENERATED FILE --
--  DO NOT MODIFY BY HAND   --
------------------------------

CREATE SCHEMA "sync";

CREATE TYPE "permission_type" AS ENUM (
  'scout.match',
  'scout.pit',
  'scout.drive_team',
  'team.manage',
  'team.admin'
);

CREATE TYPE "frc_match_level" AS ENUM (
  'qm',
  'ef',
  'qf',
  'sf',
  'f'
);

CREATE TYPE "frc_alliance" AS ENUM (
  'red',
  'blue'
);

CREATE TYPE "scouting_category" AS ENUM (
  'match',
  'pit',
  'drive_team'
);

CREATE TYPE "data_type" AS ENUM (
  'boolean',
  'number',
  'string',
  'array'
);

CREATE TABLE "profiles" (
  "user_id" uuid NOT NULL,
  "created_at" timestamptz NOT NULL,
  "name" text NOT NULL DEFAULT '',
  PRIMARY KEY ("user_id")
);

CREATE TABLE "teams" (
  "number" smallint NOT NULL,
  "verified" boolean NOT NULL DEFAULT false,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "name" text NOT NULL,
  PRIMARY KEY ("number")
);

CREATE TABLE "team_users" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "added_at" timestamptz NOT NULL DEFAULT (now()),
  "added_by" uuid DEFAULT (auth.uid()),
  PRIMARY KEY ("user_id")
);

CREATE TABLE "team_requests" (
  "user_id" uuid NOT NULL DEFAULT (auth.uid()),
  "requested_at" timestamptz NOT NULL DEFAULT (now()),
  "team_num" smallint NOT NULL,
  PRIMARY KEY ("user_id")
);

CREATE TABLE "permissions" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "granted_at" timestamptz NOT NULL DEFAULT (now()),
  "granted_by" uuid DEFAULT (auth.uid()),
  "type" permission_type NOT NULL,
  PRIMARY KEY ("user_id", "type")
);

CREATE TABLE "frc_seasons" (
  "year" smallint NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("year")
);

CREATE TABLE "frc_districts" (
  "season" smallint NOT NULL,
  "key" citext NOT NULL,
  "code" citext NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_event_types" (
  "id" smallint NOT NULL,
  "is_district" boolean NOT NULL,
  "is_championship" boolean NOT NULL,
  "is_division" boolean NOT NULL,
  "is_offseason" boolean NOT NULL,
  "name" text NOT NULL,
  "name_short" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "frc_events" (
  "season" smallint NOT NULL,
  "type" smallint NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "coordinates" point,
  "week" smallint,
  "key" citext NOT NULL,
  "code" citext NOT NULL,
  "name" text NOT NULL,
  "name_short" text,
  "district_key" citext,
  "timezone" text,
  "country" text,
  "province" text,
  "city" text,
  "address" text,
  "location" text,
  "website" text,
  "postal_code" citext,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_teams" (
  "number" smallint NOT NULL,
  "rookie_season" smallint,
  "name" text NOT NULL,
  "country" text,
  "province" text,
  "city" text,
  "postal_code" text,
  "website" text,
  PRIMARY KEY ("number")
);

CREATE TABLE "frc_event_teams" (
  "team_num" smallint NOT NULL,
  "event_key" citext NOT NULL,
  PRIMARY KEY ("event_key", "team_num")
);

CREATE TABLE "frc_matches" (
  "number" smallint NOT NULL,
  "set" smallint NOT NULL,
  "level" frc_match_level NOT NULL,
  "event_key" citext NOT NULL,
  "key" citext NOT NULL,
  "scheduled_time" timestamptz,
  "predicted_time" timestamptz,
  "actual_time" timestamptz,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_match_teams" (
  "team_num" smallint NOT NULL,
  "station" smallint NOT NULL,
  "alliance" frc_alliance NOT NULL,
  "is_surrogate" boolean NOT NULL,
  "is_disqualified" boolean NOT NULL,
  "match_key" citext NOT NULL,
  PRIMARY KEY ("match_key", "alliance", "station")
);

CREATE TABLE "frc_match_results" (
  "red_score" smallint NOT NULL,
  "blue_score" smallint NOT NULL,
  "winning_alliance" frc_alliance,
  "match_key" citext NOT NULL,
  "videos" jsonb[] NOT NULL,
  PRIMARY KEY ("match_key")
);

CREATE TABLE "frc_match_breakdowns" (
  "match_key" citext NOT NULL,
  "score_breakdown" jsonb NOT NULL,
  PRIMARY KEY ("match_key")
);

CREATE TABLE "frc_event_rankings" (
  "team_num" smallint NOT NULL,
  "rank" smallint NOT NULL,
  "event_key" citext NOT NULL
);

CREATE TABLE "questions" (
  "id" uuid NOT NULL DEFAULT (gen_random_uuid()),
  "category" scouting_category NOT NULL,
  "season" smallint NOT NULL,
  "index" smallint,
  "parent_id" uuid,
  "data_type" data_type,
  "prompt" text,
  "config" jsonb,
  PRIMARY KEY ("id")
);

CREATE TABLE "submissions" (
  "id" uuid NOT NULL DEFAULT (gen_random_uuid()),
  "category" scouting_category NOT NULL,
  "season" smallint NOT NULL,
  "scouted_team" smallint NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "scouting_user" uuid DEFAULT (auth.uid()),
  "scouting_team" smallint,
  "event_key" citext NOT NULL,
  "match_key" citext,
  PRIMARY KEY ("id")
);

CREATE TABLE "submission_data" (
  "submission_id" uuid NOT NULL,
  "question_id" uuid NOT NULL,
  "data" jsonb NOT NULL,
  PRIMARY KEY ("submission_id", "question_id")
);

CREATE TABLE "sync"."etags" (
  "modified_at" timestamptz NOT NULL,
  "key" text NOT NULL,
  "value" text NOT NULL,
  PRIMARY KEY ("key")
);

CREATE UNIQUE INDEX ON "team_users" ("team_num", "user_id");

CREATE INDEX ON "team_users" ("team_num", "added_at");

CREATE INDEX ON "team_users" ("added_by");

CREATE INDEX ON "team_requests" ("team_num", "requested_at");

CREATE INDEX ON "permissions" ("team_num", "type");

CREATE INDEX ON "permissions" ("team_num", "user_id");

CREATE INDEX ON "permissions" ("team_num", "granted_by");

CREATE UNIQUE INDEX ON "frc_districts" ("season", "code");

CREATE UNIQUE INDEX ON "frc_events" ("season", "code");

CREATE INDEX ON "frc_events" ("type", "season");

CREATE INDEX ON "frc_events" ("start_date", "end_date");

CREATE INDEX ON "frc_events" ("district_key");

CREATE UNIQUE INDEX ON "frc_event_teams" ("team_num", "event_key");

CREATE UNIQUE INDEX ON "frc_matches" ("event_key", "level", "set", "number");

CREATE INDEX ON "frc_match_teams" ("team_num", "match_key");

CREATE INDEX ON "frc_event_rankings" ("event_key", "rank");

CREATE INDEX ON "frc_event_rankings" ("team_num", "event_key");

CREATE INDEX ON "questions" ("season", "category");

CREATE UNIQUE INDEX ON "questions" ("parent_id", "index");

CREATE INDEX ON "submissions" ("season", "category");

CREATE INDEX ON "submissions" ("event_key", "scouted_team");

CREATE INDEX ON "submissions" ("match_key", "scouted_team");

CREATE INDEX ON "submissions" ("scouted_team");

CREATE INDEX ON "submissions" ("scouting_user");

CREATE INDEX ON "submissions" ("scouting_team");

COMMENT ON TABLE "profiles" IS 'A user of the platform';

COMMENT ON TABLE "teams" IS 'A team utilizing the platform';

COMMENT ON TABLE "team_users" IS 'A user''s association with a team';

COMMENT ON TABLE "team_requests" IS 'A user''s request to join a team';

COMMENT ON TABLE "permissions" IS 'A user''s permission';

COMMENT ON TABLE "frc_seasons" IS 'A competition season with a unique game';

COMMENT ON TABLE "frc_districts" IS 'A district designation for a particular season';

COMMENT ON TABLE "frc_event_types" IS 'A type of competition event';

COMMENT ON TABLE "frc_events" IS 'An event or competition';

COMMENT ON TABLE "frc_teams" IS 'A team competing in a particular season';

COMMENT ON TABLE "frc_event_teams" IS 'A team competing in an event';

COMMENT ON TABLE "frc_matches" IS 'A match at an event';

COMMENT ON TABLE "frc_match_teams" IS 'A team competing in a match';

COMMENT ON TABLE "frc_match_results" IS 'An official match result from the FMS';

COMMENT ON TABLE "submissions" IS 'A scouting data submission';

COMMENT ON TABLE "submission_data" IS 'A submission''s scouting data';

COMMENT ON TABLE "sync"."etags" IS 'A TBA ETag to reduce network traffic';

ALTER TABLE "teams" ADD FOREIGN KEY ("number") REFERENCES "frc_teams" ("number") ON DELETE RESTRICT;

ALTER TABLE "team_users" ADD FOREIGN KEY ("user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("added_by") REFERENCES "profiles" ("user_id") ON DELETE SET NULL;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("user_id") REFERENCES "profiles" ("user_id") ON DELETE CASCADE;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("team_num", "user_id") REFERENCES "team_users" ("team_num", "user_id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("team_num", "granted_by") REFERENCES "team_users" ("team_num", "user_id") ON DELETE CASCADE;

ALTER TABLE "frc_districts" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("type") REFERENCES "frc_event_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("district_key") REFERENCES "frc_districts" ("key") ON DELETE SET NULL;

ALTER TABLE "frc_teams" ADD FOREIGN KEY ("rookie_season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("team_num") REFERENCES "frc_teams" ("number") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_results" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_breakdowns" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_rankings" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "questions" ADD FOREIGN KEY ("parent_id") REFERENCES "questions" ("id") ON DELETE CASCADE;

ALTER TABLE "questions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_team") REFERENCES "frc_teams" ("number") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouting_user") REFERENCES "profiles" ("user_id") ON DELETE SET NULL;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouting_team") REFERENCES "teams" ("number") ON DELETE SET NULL;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("question_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;
