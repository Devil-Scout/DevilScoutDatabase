------------------------------
-- THIS IS A GENERATED FILE --
--  DO NOT MODIFY BY HAND   --
------------------------------

CREATE SCHEMA "sync";

CREATE TYPE "frc_alliance" AS ENUM (
  'red',
  'blue'
);

CREATE TABLE "teams" (
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("number") INCLUDE (name)
);

CREATE TABLE "users" (
  "id" uuid NOT NULL,
  "name" text NOT NULL,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("id") INCLUDE (name)
);

CREATE TABLE "team_users" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "added_by" uuid,
  "added_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id") INCLUDE (team_num)
);

CREATE TABLE "team_requests" (
  "user_id" uuid NOT NULL,
  "team_num" smallint NOT NULL,
  "requested_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id")
);

CREATE TABLE "disabled_users" (
  "user_id" uuid NOT NULL,
  "disabled_by" uuid NOT NULL,
  "disabled_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id")
);

CREATE TABLE "permission_types" (
  "id" citext NOT NULL,
  "name" text NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "permissions" (
  "user_id" uuid NOT NULL,
  "type" citext NOT NULL,
  "team_num" smallint NOT NULL,
  "granted_by" uuid,
  "granted_at" timestamptz NOT NULL,
  PRIMARY KEY ("user_id", "type")
);

CREATE TABLE "frc_seasons" (
  "year" smallint NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("year")
);

CREATE TABLE "frc_districts" (
  "key" citext NOT NULL,
  "season" smallint NOT NULL,
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
  "key" citext NOT NULL,
  "name" text NOT NULL,
  "name_short" text,
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "district_key" citext,
  "type" smallint,
  "start_date" date NOT NULL,
  "end_date" date NOT NULL,
  "timezone" text,
  "week" smallint,
  "website" text,
  "location" text,
  "address" text,
  "city" text,
  "province" text,
  "country" text,
  "postal_code" citext,
  "coordinates" point,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_teams" (
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "rookie_season" smallint,
  "website" text,
  "city" text,
  "province" text,
  "country" text,
  "postal_code" text,
  PRIMARY KEY ("number")
);

CREATE TABLE "frc_event_teams" (
  "event_key" citext NOT NULL,
  "team_num" smallint NOT NULL,
  PRIMARY KEY ("event_key", "team_num")
);

CREATE TABLE "frc_match_levels" (
  "id" citext NOT NULL,
  "name" citext NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "frc_matches" (
  "key" citext NOT NULL,
  "event_key" citext NOT NULL,
  "level" citext NOT NULL,
  "set" smallint NOT NULL,
  "number" smallint NOT NULL,
  "scheduled_time" timestamptz,
  "predicted_time" timestamptz,
  "actual_time" timestamptz,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_match_teams" (
  "match_key" citext NOT NULL,
  "alliance" frc_alliance NOT NULL,
  "station" smallint NOT NULL,
  "team_num" smallint NOT NULL,
  "is_surrogate" boolean NOT NULL,
  "is_disqualified" boolean NOT NULL,
  PRIMARY KEY ("match_key", "alliance", "station")
);

CREATE TABLE "frc_match_results" (
  "match_key" citext NOT NULL,
  "red_score" smallint NOT NULL,
  "blue_score" smallint NOT NULL,
  "winning_alliance" frc_alliance,
  "videos" jsonb[] NOT NULL,
  "score_breakdown" jsonb,
  PRIMARY KEY ("match_key")
);

CREATE TABLE "frc_event_rankings" (
  "event_key" citext NOT NULL,
  "team_num" smallint NOT NULL,
  "rank" smallint NOT NULL
);

CREATE TABLE "categories" (
  "id" citext NOT NULL,
  "has_match" bool NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "questions" (
  "id" uuid NOT NULL,
  "parent_id" uuid,
  "index" smallint NOT NULL,
  "season" smallint NOT NULL,
  "category" citext NOT NULL,
  "type" citext NOT NULL,
  "prompt" text,
  "config" jsonb,
  "info_path" text,
  PRIMARY KEY ("id")
);

CREATE TABLE "submissions" (
  "id" uuid NOT NULL,
  "category" citext NOT NULL,
  "season" smallint NOT NULL,
  "event_key" citext NOT NULL,
  "match_key" citext,
  "team_num" smallint NOT NULL,
  "scouted_by" uuid,
  "scouted_for" smallint,
  "created_at" timestamptz NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "submission_data" (
  "submission_id" uuid NOT NULL,
  "question_id" uuid NOT NULL,
  "data" jsonb NOT NULL,
  PRIMARY KEY ("submission_id", "question_id")
);

CREATE TABLE "sync"."etags" (
  "key" text NOT NULL,
  "value" text NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("key") INCLUDE (value)
);

CREATE UNIQUE INDEX ON "team_users" ("team_num", "user_id");

CREATE INDEX ON "team_users" ("team_num", "added_at");

CREATE INDEX ON "team_users" ("added_by");

CREATE INDEX ON "team_requests" ("team_num", "requested_at") INCLUDE (user_id);

CREATE INDEX ON "disabled_users" ("disabled_by");

CREATE INDEX ON "permissions" ("team_num", "type");

CREATE INDEX ON "permissions" ("team_num", "user_id");

CREATE INDEX ON "permissions" ("team_num", "granted_by");

CREATE UNIQUE INDEX ON "frc_districts" ("season", "code");

CREATE UNIQUE INDEX ON "frc_events" ("season", "code");

CREATE INDEX ON "frc_events" ("type", "season");

CREATE INDEX ON "frc_events" ("start_date", "end_date");

CREATE INDEX ON "frc_events" ("district_key");

CREATE UNIQUE INDEX ON "frc_event_teams" ("team_num", "event_key");

CREATE UNIQUE INDEX ON "frc_match_levels" ("name");

CREATE UNIQUE INDEX ON "frc_matches" ("event_key", "level", "set", "number");

CREATE INDEX ON "frc_match_teams" ("team_num", "match_key");

CREATE INDEX ON "frc_event_rankings" ("event_key", "rank");

CREATE INDEX ON "frc_event_rankings" ("team_num", "event_key");

CREATE UNIQUE INDEX ON "questions" ("season", "category", "id");

CREATE UNIQUE INDEX ON "questions" ("parent_id", "index");

CREATE INDEX ON "questions" ("category");

CREATE INDEX ON "submissions" ("season");

CREATE INDEX ON "submissions" ("category");

CREATE INDEX ON "submissions" ("event_key");

CREATE INDEX ON "submissions" ("match_key", "team_num");

CREATE INDEX ON "submissions" ("team_num");

CREATE INDEX ON "submissions" ("scouted_by");

CREATE INDEX ON "submissions" ("scouted_for");

COMMENT ON TABLE "teams" IS 'A team utilizing the platform';

COMMENT ON TABLE "users" IS 'A user of the platform';

COMMENT ON TABLE "team_users" IS 'A user''s association with a team';

COMMENT ON TABLE "team_requests" IS 'A user''s request to join a team';

COMMENT ON TABLE "disabled_users" IS 'A user whose privileges have been temporarily revoked';

COMMENT ON TABLE "permission_types" IS 'Types of permissions users may hold';

COMMENT ON TABLE "permissions" IS 'A user''s permission';

COMMENT ON TABLE "frc_seasons" IS 'A competition season with a unique game';

COMMENT ON TABLE "frc_districts" IS 'A district designation for a particular season';

COMMENT ON TABLE "frc_event_types" IS 'A type of competition event';

COMMENT ON TABLE "frc_events" IS 'An event or competition';

COMMENT ON TABLE "frc_teams" IS 'A team competing in a particular season';

COMMENT ON TABLE "frc_event_teams" IS 'A team competing in an event';

COMMENT ON TABLE "frc_match_levels" IS 'A level of competition for matches';

COMMENT ON TABLE "frc_matches" IS 'A match at an event';

COMMENT ON TABLE "frc_match_teams" IS 'A team competing in a match';

COMMENT ON TABLE "frc_match_results" IS 'An official match result from the FMS';

COMMENT ON TABLE "categories" IS 'A type of scouting data users can submit';

COMMENT ON TABLE "submissions" IS 'A scouting data submission';

COMMENT ON TABLE "submission_data" IS 'A submission''s scouting data';

COMMENT ON TABLE "sync"."etags" IS 'A TBA ETag to reduce network traffic';

ALTER TABLE "team_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "team_users" ADD FOREIGN KEY ("added_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "team_requests" ADD FOREIGN KEY ("team_num") REFERENCES "teams" ("number") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "disabled_users" ADD FOREIGN KEY ("disabled_by") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("type") REFERENCES "permission_types" ("id") ON DELETE CASCADE;

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

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("level") REFERENCES "frc_match_levels" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_results" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_rankings" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "questions" ADD FOREIGN KEY ("parent_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("team_num") REFERENCES "frc_teams" ("number") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_for") REFERENCES "teams" ("number") ON DELETE SET NULL;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("question_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;
