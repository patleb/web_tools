--
-- Name: rpc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA rpc;


CREATE FUNCTION rpc.get_json(_json json, _float_a double precision[], _float_a_opt double precision[] DEFAULT ARRAY[0.05, 0.95]) RETURNS json
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_jsonb(_text text, _bigint bigint, _jsonb jsonb) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_jsonb(_text text, _bigint bigint, _jsonb jsonb, _integer_opt integer DEFAULT 100, _text_opt text DEFAULT 'some text'::text) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_integer(_timestamp timestamp without time zone, _jsonb jsonb) RETURNS bigint
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_float(_integer integer, _float_a double precision[]) RETURNS double precision
    LANGUAGE plpgsql STABLE SECURITY DEFINER
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_float_a(_text text) RETURNS double precision[]
    LANGUAGE plpgsql STABLE
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_text(_text text, _text_a_opt text[] DEFAULT ARRAY[]::text[], _integer_opt integer DEFAULT 1) RETURNS text
    LANGUAGE plpgsql STABLE
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_text_a(_text text, _text_a_opt text[] DEFAULT ARRAY[]::text[]) RETURNS text[]
    LANGUAGE plpgsql STABLE
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_integer_set(_text text, _bigint bigint) RETURNS SETOF integer
    LANGUAGE plpgsql STABLE
AS $$ BEGIN; END; $$;

CREATE FUNCTION rpc.get_table_rows(_text text, _bigint bigint) RETURNS TABLE(_float double precision, _geometry public.geometry)
    LANGUAGE plpgsql STABLE
AS $$ BEGIN; END; $$;


--
-- Name: healthcheck(); Type: FUNCTION; Schema: api; Owner: -
--

CREATE FUNCTION rpc.healthcheck() RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$ BEGIN; END; $$;


--
-- Name: count_estimate(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_estimate(query text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$ BEGIN; END; $$;
