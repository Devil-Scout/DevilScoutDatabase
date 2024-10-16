------------------------------
-- THIS IS A GENERATED FILE --
--  DO NOT MODIFY BY HAND   --
------------------------------

CREATE SCHEMA "sync";

CREATE TYPE "frc_alliance" AS ENUM (
  'red',
  'blue'
);

CREATE TYPE "data_type" AS ENUM (
  'boolean',
  'int',
  'text'
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
  "game_name" text NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("year")
);

CREATE TABLE "frc_districts" (
  "key" citext NOT NULL,
  "season" smallint NOT NULL,
  "code" citext NOT NULL,
  "name" text NOT NULL,
  "modified_at" timestamptz NOT NULL,
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
  "timezone" text NOT NULL,
  "week" smallint,
  "website" text,
  "location" text,
  "address" text,
  "city" text,
  "province" text,
  "country" text,
  "postal_code" citext,
  "coordinates" point,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_teams" (
  "number" smallint NOT NULL,
  "name" text NOT NULL,
  "rookie_season" smallint,
  "website" text,
  "location" text,
  "address" text,
  "city" text,
  "province" text,
  "country" text,
  "postal_code" text,
  "coordinates" point,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("number")
);

CREATE TABLE "frc_event_teams" (
  "team_num" smallint NOT NULL,
  "event_key" citext NOT NULL,
  "modified_at" timestamptz NOT NULL,
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
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("key")
);

CREATE TABLE "frc_match_teams" (
  "match_key" citext NOT NULL,
  "team_num" smallint NOT NULL,
  "alliance" frc_alliance NOT NULL,
  "is_surrogate" boolean NOT NULL,
  "is_disqualified" boolean NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("match_key", "team_num")
);

CREATE TABLE "frc_match_results" (
  "match_key" citext NOT NULL,
  "red_score" smallint NOT NULL,
  "blue_score" smallint NOT NULL,
  "videos" text[] NOT NULL,
  "red_breakdown" jsonb,
  "blue_breakdown" jsonb,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("match_key")
);

CREATE TABLE "question_types" (
  "id" citext NOT NULL,
  "name" text NOT NULL,
  "type" data_type NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "categories" (
  "id" citext NOT NULL,
  "has_match" bool NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "question_sections" (
  "id" uuid NOT NULL,
  "season" smallint NOT NULL,
  "category" citext NOT NULL,
  "index" smallint NOT NULL,
  "name" text NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "questions" (
  "id" uuid NOT NULL,
  "section_id" uuid NOT NULL,
  "index" smallint NOT NULL,
  "prompt" text NOT NULL,
  "type" citext NOT NULL,
  "config" jsonb NOT NULL DEFAULT '{}',
  "info_filepath" text,
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
  "value_bool" boolean,
  "value_int" bigint,
  "value_text" text[],
  PRIMARY KEY ("submission_id", "question_id")
);

CREATE TABLE "sync"."etags" (
  "key" text NOT NULL,
  "value" text NOT NULL,
  "modified_at" timestamptz NOT NULL,
  PRIMARY KEY ("key")
);

CREATE UNIQUE INDEX ON "team_users" ("team_num", "user_id");

CREATE INDEX ON "team_users" ("team_num", "added_at");

CREATE INDEX ON "team_users" ("added_by");

CREATE INDEX ON "team_requests" ("team_num", "requested_at") INCLUDE (user_id);

CREATE INDEX ON "disabled_users" ("disabled_by");

CREATE INDEX ON "permissions" ("type", "team_num");

CREATE INDEX ON "permissions" ("user_id", "team_num");

CREATE INDEX ON "permissions" ("granted_by", "team_num");

CREATE INDEX ON "frc_seasons" ("modified_at");

CREATE UNIQUE INDEX ON "frc_districts" ("season", "code");

CREATE INDEX ON "frc_districts" ("modified_at");

CREATE UNIQUE INDEX ON "frc_events" ("season", "code");

CREATE INDEX ON "frc_events" ("season", "type", "key");

CREATE INDEX ON "frc_events" ("season", "name");

CREATE INDEX ON "frc_events" ("season", "country", "province");

CREATE INDEX ON "frc_events" ("season", "start_date", "end_date");

CREATE INDEX ON "frc_events" ("district_key");

CREATE INDEX ON "frc_events" ("type");

CREATE INDEX ON "frc_events" ("modified_at");

CREATE INDEX ON "frc_teams" ("name");

CREATE INDEX ON "frc_teams" ("rookie_season");

CREATE INDEX ON "frc_teams" ("country", "province", "city");

CREATE INDEX ON "frc_teams" ("modified_at");

CREATE UNIQUE INDEX ON "frc_event_teams" ("team_num", "event_key");

CREATE INDEX ON "frc_event_teams" ("modified_at");

CREATE UNIQUE INDEX ON "frc_match_levels" ("name");

CREATE UNIQUE INDEX ON "frc_matches" ("event_key", "level", "set", "number");

CREATE INDEX ON "frc_matches" ("event_key", "scheduled_time");

CREATE INDEX ON "frc_matches" ("event_key", "predicted_time");

CREATE INDEX ON "frc_matches" ("event_key", "actual_time");

CREATE INDEX ON "frc_matches" ("modified_at");

CREATE INDEX ON "frc_matches" ("level");

CREATE INDEX ON "frc_match_teams" ("team_num", "match_key");

CREATE INDEX ON "frc_match_teams" ("modified_at");

CREATE INDEX ON "frc_match_results" ("modified_at");

CREATE UNIQUE INDEX ON "question_sections" ("season", "category", "index");

CREATE INDEX ON "question_sections" ("category");

CREATE INDEX ON "questions" ("section_id");

CREATE INDEX ON "questions" ("type");

CREATE INDEX ON "submissions" ("category");

CREATE INDEX ON "submissions" ("event_key");

CREATE INDEX ON "submissions" ("match_key");

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

COMMENT ON TABLE "question_types" IS 'A type of scouting question shown to the user';

COMMENT ON TABLE "categories" IS 'A type of scouting data users can submit';

COMMENT ON TABLE "question_sections" IS 'A section within a set of scouting questions';

COMMENT ON TABLE "questions" IS 'A scouting question that users must answer';

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

ALTER TABLE "permissions" ADD FOREIGN KEY ("user_id", "team_num") REFERENCES "team_users" ("user_id", "team_num") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("granted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "permissions" ADD FOREIGN KEY ("granted_by", "team_num") REFERENCES "team_users" ("user_id", "team_num") ON DELETE CASCADE;

ALTER TABLE "permissions" ADD FOREIGN KEY ("type") REFERENCES "permission_types" ("id") ON DELETE CASCADE;

ALTER TABLE "frc_districts" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE CASCADE;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("type") REFERENCES "frc_event_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_events" ADD FOREIGN KEY ("district_key") REFERENCES "frc_districts" ("key") ON DELETE SET NULL;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_event_teams" ADD FOREIGN KEY ("team_num") REFERENCES "frc_teams" ("number") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_matches" ADD FOREIGN KEY ("level") REFERENCES "frc_match_levels" ("id") ON DELETE RESTRICT;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "frc_match_teams" ADD FOREIGN KEY ("team_num") REFERENCES "frc_teams" ("number") ON DELETE CASCADE;

ALTER TABLE "frc_match_results" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE CASCADE;

ALTER TABLE "question_sections" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "questions" ADD FOREIGN KEY ("section_id") REFERENCES "question_sections" ("id");

ALTER TABLE "questions" ADD FOREIGN KEY ("type") REFERENCES "question_types" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("event_key") REFERENCES "frc_events" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key") REFERENCES "frc_matches" ("key") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("match_key", "team_num") REFERENCES "frc_match_teams" ("match_key", "team_num") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("season") REFERENCES "frc_seasons" ("year") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("team_num") REFERENCES "frc_teams" ("number") ON DELETE RESTRICT;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_by") REFERENCES "users" ("id") ON DELETE SET NULL;

ALTER TABLE "submissions" ADD FOREIGN KEY ("scouted_for") REFERENCES "teams" ("number") ON DELETE SET NULL;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("submission_id") REFERENCES "submissions" ("id") ON DELETE CASCADE;

ALTER TABLE "submission_data" ADD FOREIGN KEY ("question_id") REFERENCES "questions" ("id") ON DELETE RESTRICT;
