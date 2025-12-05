--
-- PostgreSQL database dump
--

\restrict cwidXu5O4xkeSqyk7M2tyvSz8rXbYa4SNrOg9ZwoOHcMA8PUMVbfuhYRbIUr5Qg

-- Dumped from database version 15.14
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hazardtype; Type: TYPE; Schema: public; Owner: admindb
--

CREATE TYPE public.hazardtype AS ENUM (
    'HIGH_WAVES',
    'FLOODING',
    'TSUNAMI',
    'LOST_VESSEL',
    'DEBRIS',
    'OIL_SPILL',
    'OTHER'
);


ALTER TYPE public.hazardtype OWNER TO admindb;

--
-- Name: incidentstatus; Type: TYPE; Schema: public; Owner: admindb
--

CREATE TYPE public.incidentstatus AS ENUM (
    'PENDING',
    'VERIFIED',
    'IN_PROGRESS',
    'RESOLVED',
    'FALSE_ALARM'
);


ALTER TYPE public.incidentstatus OWNER TO admindb;

--
-- Name: urgencylevel; Type: TYPE; Schema: public; Owner: admindb
--

CREATE TYPE public.urgencylevel AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);


ALTER TYPE public.urgencylevel OWNER TO admindb;

--
-- Name: userrole; Type: TYPE; Schema: public; Owner: admindb
--

CREATE TYPE public.userrole AS ENUM (
    'PUBLIC',
    'ADMIN',
    'AUTHORITY',
    'RESCUE_TEAM'
);


ALTER TYPE public.userrole OWNER TO admindb;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: analytics_snapshots; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.analytics_snapshots (
    id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    total_incidents integer,
    active_incidents integer,
    resolved_incidents integer,
    false_alarms integer,
    average_response_time_hours double precision,
    incidents_by_type text,
    incidents_by_region text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.analytics_snapshots OWNER TO admindb;

--
-- Name: analytics_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.analytics_snapshots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analytics_snapshots_id_seq OWNER TO admindb;

--
-- Name: analytics_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.analytics_snapshots_id_seq OWNED BY public.analytics_snapshots.id;


--
-- Name: incidents; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.incidents (
    id integer NOT NULL,
    reference_id character varying(50) NOT NULL,
    hazard_type public.hazardtype NOT NULL,
    location character varying(255) NOT NULL,
    latitude double precision,
    longitude double precision,
    description text NOT NULL,
    urgency public.urgencylevel NOT NULL,
    status public.incidentstatus NOT NULL,
    contact_info character varying(100),
    photo_url character varying(500),
    reporter_id integer NOT NULL,
    verified_by_id integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    verified_at timestamp with time zone,
    resolved_at timestamp with time zone
);


ALTER TABLE public.incidents OWNER TO admindb;

--
-- Name: incidents_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.incidents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.incidents_id_seq OWNER TO admindb;

--
-- Name: incidents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.incidents_id_seq OWNED BY public.incidents.id;


--
-- Name: system_metrics; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.system_metrics (
    id integer NOT NULL,
    metric_name character varying(100) NOT NULL,
    metric_value double precision NOT NULL,
    metric_unit character varying(20),
    description text,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


ALTER TABLE public.system_metrics OWNER TO admindb;

--
-- Name: system_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.system_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_metrics_id_seq OWNER TO admindb;

--
-- Name: system_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.system_metrics_id_seq OWNED BY public.system_metrics.id;


--
-- Name: user_visits; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.user_visits (
    id integer NOT NULL,
    ip_address character varying(45) NOT NULL,
    user_agent text,
    country character varying(100),
    city character varying(100),
    region character varying(100),
    latitude double precision,
    longitude double precision,
    timezone character varying(50),
    language character varying(10),
    referrer text,
    page_url text,
    session_id character varying(100),
    user_id integer,
    visit_duration integer,
    device_type character varying(20),
    browser character varying(50),
    os character varying(50),
    is_bot boolean,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.user_visits OWNER TO admindb;

--
-- Name: user_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.user_visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_visits_id_seq OWNER TO admindb;

--
-- Name: user_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.user_visits_id_seq OWNED BY public.user_visits.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone character varying(15),
    location character varying(100),
    role public.userrole NOT NULL,
    is_active boolean NOT NULL,
    is_verified boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    last_login timestamp with time zone
);


ALTER TABLE public.users OWNER TO admindb;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO admindb;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: website_stats; Type: TABLE; Schema: public; Owner: admindb
--

CREATE TABLE public.website_stats (
    id integer NOT NULL,
    date timestamp with time zone NOT NULL,
    total_visits integer,
    unique_visitors integer,
    page_views integer,
    bounce_rate double precision,
    avg_session_duration double precision,
    top_countries text,
    top_pages text,
    device_breakdown text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.website_stats OWNER TO admindb;

--
-- Name: website_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: admindb
--

CREATE SEQUENCE public.website_stats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.website_stats_id_seq OWNER TO admindb;

--
-- Name: website_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: admindb
--

ALTER SEQUENCE public.website_stats_id_seq OWNED BY public.website_stats.id;


--
-- Name: analytics_snapshots id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.analytics_snapshots ALTER COLUMN id SET DEFAULT nextval('public.analytics_snapshots_id_seq'::regclass);


--
-- Name: incidents id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.incidents ALTER COLUMN id SET DEFAULT nextval('public.incidents_id_seq'::regclass);


--
-- Name: system_metrics id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.system_metrics ALTER COLUMN id SET DEFAULT nextval('public.system_metrics_id_seq'::regclass);


--
-- Name: user_visits id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.user_visits ALTER COLUMN id SET DEFAULT nextval('public.user_visits_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: website_stats id; Type: DEFAULT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.website_stats ALTER COLUMN id SET DEFAULT nextval('public.website_stats_id_seq'::regclass);


--
-- Data for Name: analytics_snapshots; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.analytics_snapshots (id, date, total_incidents, active_incidents, resolved_incidents, false_alarms, average_response_time_hours, incidents_by_type, incidents_by_region, created_at) FROM stdin;
\.


--
-- Data for Name: incidents; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.incidents (id, reference_id, hazard_type, location, latitude, longitude, description, urgency, status, contact_info, photo_url, reporter_id, verified_by_id, created_at, updated_at, verified_at, resolved_at) FROM stdin;
1	OG-20251011014922-E1D7B3CD	HIGH_WAVES	11.913747, 79.648577	11.913747	79.648577	ad	HIGH	RESOLVED	dad	\N	4	3	2025-10-10 20:19:22.603569+00	2025-10-11 18:29:38.213951+00	2025-10-11 12:59:30.241729+00	2025-10-11 12:59:36.659491+00
2	OG-20251014153703-5EFBF9D2	LOST_VESSEL	11.127123, 78.656894	11.127123	78.656894	Here is a floating boat 	HIGH	PENDING	asa	\N	11	\N	2025-10-14 15:37:03.146695+00	\N	\N	\N
3	OG-20251014155233-B30519FE	FLOODING	Test Location	\N	\N	Test incident for debugging	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 15:52:32.738577+00	\N	\N	\N
4	OG-20251014155322-B039B719	FLOODING	Test Location	\N	\N	Test incident for debugging	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 15:53:21.9933+00	\N	\N	\N
5	OG-20251014155402-61D6BB6D	FLOODING	Test Location	\N	\N	Test incident for debugging	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 15:54:02.611988+00	\N	\N	\N
6	OG-20251014155545-77AB6C40	FLOODING	Test Location	\N	\N	Test incident for debugging	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 15:55:45.080141+00	\N	\N	\N
7	OG-20251014155616-4F9D0AEE	OTHER	Test Location	\N	\N	Test incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 15:56:15.843333+00	\N	\N	\N
8	OG-20251014160127-2063EA73	HIGH_WAVES	11.127123, 78.656894	11.127123	78.656894	adals	MEDIUM	PENDING	77	\N	11	\N	2025-10-14 16:01:27.089604+00	\N	\N	\N
9	OG-20251014160158-38FE47B8	FLOODING	11.127123, 78.656894	11.127123	78.656894	dsads	HIGH	PENDING	578	\N	11	\N	2025-10-14 16:01:58.058272+00	\N	\N	\N
10	OG-20251014160400-8D929D9F	FLOODING	Test Location	\N	\N	Test incident for debugging	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 16:04:00.175322+00	\N	\N	\N
11	OG-20251014160501-ACF99D9B	FLOODING	Test Location	\N	\N	Test incident	MEDIUM	PENDING	\N	\N	18	\N	2025-10-14 16:05:01.20462+00	\N	\N	\N
12	OG-20251014160613-4844A5DC	OTHER	Test Location	\N	\N	Test incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 16:06:13.655793+00	\N	\N	\N
13	OG-20251014160616-3360A774	FLOODING	Test Location	\N	\N	Test flood incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 16:06:15.992259+00	\N	\N	\N
14	OG-20251014160739-8CB47EAE	OTHER	Test Location	\N	\N	Test incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 16:07:39.456576+00	\N	\N	\N
15	OG-20251014160742-CA839334	FLOODING	Test Location	\N	\N	Test flood incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 16:07:41.827177+00	\N	\N	\N
16	OG-20251014160828-49AFD668	OTHER	Test Location	\N	\N	Test incident	LOW	PENDING	\N	\N	18	\N	2025-10-14 16:08:28.564106+00	\N	\N	\N
19	OG-20251015171416-97FE416A	OTHER	11.913739, 79.648579	11.913739	79.648579	test2	HIGH	PENDING	15	\N	11	\N	2025-10-15 17:14:16.301161+00	\N	\N	\N
18	OG-20251014163221-97A6E34B	HIGH_WAVES	11.127123, 78.656894	11.127123	78.656894	ss	HIGH	RESOLVED		\N	19	20	2025-10-14 16:32:20.981175+00	2025-10-15 18:11:41.686255+00	2025-10-15 18:11:28.303638+00	2025-10-15 18:11:42.235069+00
17	OG-20251014160832-EEF662C2	FLOODING	Test Location	\N	\N	Test flood incident	LOW	RESOLVED	\N	\N	18	27	2025-10-14 16:08:31.885674+00	2025-10-16 06:02:34.893198+00	2025-10-16 06:02:04.659504+00	2025-10-16 06:02:35.440638+00
\.


--
-- Data for Name: system_metrics; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.system_metrics (id, metric_name, metric_value, metric_unit, description, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_visits; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.user_visits (id, ip_address, user_agent, country, city, region, latitude, longitude, timezone, language, referrer, page_url, session_id, user_id, visit_duration, device_type, browser, os, is_bot, created_at) FROM stdin;
1	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/authority-analytics.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:21:05.032605+00
2	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/admin-dashboard.html	http://localhost:3000/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:24:54.77086+00
3	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/index.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:24:58.20594+00
4	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:36:23.47471+00
5	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:37:16.793043+00
6	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:39:11.080469+00
7	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:39:14.011604+00
8	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:39:52.086861+00
9	127.0.0.1	Test Browser	Test Country	\N	\N	\N	\N	\N			http://test.com	test-session-123	\N	\N	desktop			f	2025-10-16 18:44:06.292047+00
10	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:48:07.563821+00
11	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/admin-dashboard.html	http://localhost:3000/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:48:11.098368+00
12	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/index.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:48:24.673613+00
13	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/pages/visitor_details.html	http://localhost:3000/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-10-16 18:49:28.444821+00
14	unknown	vercel-screenshot/1.0	\N	\N	\N	\N	\N	\N	en-US	https://ocean-sentinels-qcqurzqhs-gowshik-projects.vercel.app/	https://ocean-sentinels-qcqurzqhs-gowshik-projects.vercel.app/pages/index.html	session_1760641356405_2jabm54cj	\N	\N	desktop	unknown	unknown	f	2025-10-16 19:02:42.219034+00
15	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-qcqurzqhs-gowshik-projects.vercel.app/	https://ocean-sentinels-qcqurzqhs-gowshik-projects.vercel.app/pages/index.html	session_1760641358709_4cf3bmljl	\N	\N	desktop	Chrome	Windows	f	2025-10-16 19:02:45.309492+00
16	unknown	vercel-screenshot/1.0	\N	\N	\N	\N	\N	\N	en-US	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/index.html	session_1760641583419_08teaj2g6	\N	\N	desktop	unknown	unknown	f	2025-10-16 19:06:24.795788+00
17	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/index.html	session_1760641587121_6tswmdvpw	\N	\N	desktop	Chrome	Windows	f	2025-10-16 19:06:29.55981+00
18	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760641587121_6tswmdvpw	\N	\N	desktop	Chrome	Windows	f	2025-10-16 19:06:45.768854+00
19	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/index.html	session_1760641587121_6tswmdvpw	\N	\N	desktop	Chrome	Windows	f	2025-10-16 19:07:41.052746+00
20	103.208.230.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-p23ad0iz7-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760641587121_6tswmdvpw	\N	\N	desktop	Chrome	Windows	f	2025-10-16 19:07:42.96948+00
21	144.217.253.149	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	Canada	Beauharnois	Quebec	45.3161	-73.8736	America/Toronto	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760643935991_yosgmi30g	\N	\N	desktop	Edge	Windows	f	2025-10-16 19:45:42.654139+00
22	144.217.253.149	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	Canada	Beauharnois	Quebec	45.3161	-73.8736	America/Toronto	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760643935991_yosgmi30g	\N	\N	desktop	Edge	Windows	f	2025-10-16 19:46:00.138101+00
23	144.217.253.149	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	Canada	Beauharnois	Quebec	45.3161	-73.8736	America/Toronto	en-US	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760643935991_yosgmi30g	\N	\N	desktop	Edge	Windows	f	2025-10-16 19:47:17.471916+00
24	144.217.253.149	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	Canada	Beauharnois	Quebec	45.3161	-73.8736	America/Toronto	en-US	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760643935991_yosgmi30g	\N	\N	desktop	Edge	Windows	f	2025-10-16 19:47:55.561827+00
25	45.249.79.120	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Markapur	Andhra Pradesh	15.73534	79.26848	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760679186245_w397yoz1g	\N	\N	mobile	Chrome	Linux	f	2025-10-17 05:33:12.448767+00
26	49.44.83.4	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36	India	Nangloi Jat	Delhi	28.672	77.0637	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760679189864_w93r78mxu	\N	\N	mobile	Chrome	Linux	f	2025-10-17 05:33:20.966201+00
27	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760681605044_r1c2lqbdm	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:13:44.078732+00
28	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760681605044_r1c2lqbdm	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:13:58.825248+00
29	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:17:55.492153+00
30	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:18:25.709765+00
31	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:26:54.397503+00
32	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:26:54.960775+00
33	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:28:00.596114+00
34	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:29:06.051619+00
35	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-GB	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760681856242_voptezov4	\N	\N	desktop	Edge	Windows	f	2025-10-17 06:29:07.403615+00
36	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36	India	Coimbatore	Tamil Nadu	11.0102	76.9701	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760708969679_fb6xg1pn3	\N	\N	desktop	Chrome	Windows	f	2025-10-17 13:52:00.933498+00
37	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760708969679_fb6xg1pn3	\N	\N	desktop	Chrome	Windows	f	2025-10-17 13:57:07.813716+00
38	223.178.85.245	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760710555801_tei4zyxsj	\N	\N	desktop	Edge	Windows	f	2025-10-17 14:15:57.526461+00
39	223.178.85.245	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760710555801_tei4zyxsj	\N	\N	desktop	Edge	Windows	f	2025-10-17 14:16:22.046963+00
40	223.178.85.245	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760710555801_tei4zyxsj	\N	\N	desktop	Edge	Windows	f	2025-10-17 14:16:30.641132+00
41	223.178.85.245	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760710555801_tei4zyxsj	\N	\N	desktop	Edge	Windows	f	2025-10-17 14:17:00.382548+00
42	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 16:56:55.80606+00
45	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 18:36:02.874399+00
49	103.208.230.111	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:16:08.093688+00
50	103.208.231.61	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	session_1760768251230_v9bkkh3eu	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:17:35.493291+00
51	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-o8l5zo0jz-gowshik-projects.vercel.app/	https://ocean-sentinels-o8l5zo0jz-gowshik-projects.vercel.app/pages/index.html	session_1760768290637_yc4lunzoc	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:18:12.507498+00
43	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 16:59:30.735405+00
46	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 18:36:04.388954+00
44	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 16:59:43.355285+00
47	103.208.231.65	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-17 18:36:08.153182+00
48	103.208.230.111	Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760787902564_o4l58ki4d	\N	\N	desktop	Firefox	Linux	f	2025-10-18 06:15:05.157616+00
52	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760768251230_v9bkkh3eu	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:20:11.569717+00
53	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768504699_lj73i7z0z	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:21:46.477451+00
54	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768504699_lj73i7z0z	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:22:02.892547+00
55	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760768504699_lj73i7z0z	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:22:06.361343+00
56	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/pages/index.html	session_1760768748564_isqmzx9qn	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:25:54.413336+00
57	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/pages/index.html	session_1760768748564_isqmzx9qn	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:20.022395+00
58	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:22.382428+00
59	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:24.932716+00
60	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/admin-dashboard.html	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	session_1760768251230_v9bkkh3eu	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:38.177017+00
61	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	session_1760768251230_v9bkkh3eu	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:41.161785+00
62	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:28:53.619913+00
63	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/admin-dashboard.html	https://ocean-sentinels-git-back-gow-gowshik-projects.vercel.app/pages/index.html	session_1760768251230_v9bkkh3eu	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:29:09.572784+00
64	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:36:27.701793+00
65	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:36:36.687537+00
66	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:37:17.63554+00
67	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:37:22.922218+00
68	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:38:20.655445+00
69	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/pages/index.html	session_1760768748564_isqmzx9qn	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:38:40.422342+00
70	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/pages/my-reports.html	https://ocean-sentinels-cxs2uu5d3-gowshik-projects.vercel.app/pages/index.html	session_1760768748564_isqmzx9qn	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:40:19.958276+00
72	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760769718532_prxw6w1vu	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:43:30.088078+00
71	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760769718532_prxw6w1vu	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:42:00.442838+00
73	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760769718532_prxw6w1vu	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:44:42.284489+00
74	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760769718532_prxw6w1vu	\N	\N	desktop	Edge	Windows	f	2025-10-18 06:44:47.939938+00
75	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:46:26.261265+00
76	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/my-reports.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:46:47.666576+00
77	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:46:50.873171+00
78	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/reports.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:47:12.820747+00
79	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:47:57.481803+00
80	103.208.230.128	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	mobile	Chrome	Linux	f	2025-10-18 06:48:10.708723+00
81	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:48:20.59551+00
82	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:48:34.727468+00
83	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/admin-dashboard.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:48:49.506885+00
84	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:49:13.877718+00
85	103.208.230.128	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760770080337_kxdfudm3h	\N	\N	mobile	Chrome	Linux	f	2025-10-18 06:50:16.702586+00
86	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:51:09.374337+00
87	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:52:38.983006+00
88	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:54:30.441109+00
89	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:54:31.93939+00
90	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:54:34.719607+00
91	103.208.230.128	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	mobile	Chrome	Linux	f	2025-10-18 06:54:50.129509+00
93	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:55:04.484427+00
92	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-18 06:54:56.878367+00
94	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/admin-dashboard.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:56:21.993267+00
95	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-mr7vvidoj-gowshik-projects.vercel.app/pages/index.html	session_1760769982539_ymm5kecbl	\N	\N	desktop	Chrome	Windows	f	2025-10-18 06:56:24.955355+00
96	103.208.230.117	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 12:28:28.492101+00
97	103.208.230.117	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 12:29:53.561642+00
98	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#about-us	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 12:31:44.494329+00
99	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:33:47.964548+00
100	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:34:18.49308+00
101	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:35:29.365637+00
102	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:35:41.19643+00
103	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:35:44.168807+00
104	103.208.230.129	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 13:36:01.840046+00
105	120.138.12.107	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 17:08:34.047875+00
106	120.138.12.107	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760790503339_eu5e1zxo7	\N	\N	desktop	Chrome	Windows	f	2025-10-18 17:08:44.551434+00
107	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760859382865_7kdu3dxpf	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:36:28.157854+00
108	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760859382865_7kdu3dxpf	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:36:48.264685+00
109	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:45:03.690296+00
110	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:45:50.223795+00
111	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:54:47.48635+00
112	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760643935991_yosgmi30g	\N	\N	desktop	Edge	Windows	f	2025-10-19 07:55:48.150796+00
113	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:58:54.439535+00
114	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 07:59:31.065389+00
115	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 08:04:46.949327+00
116	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 08:09:06.178265+00
126	103.197.112.37	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 14:21:07.011679+00
132	103.197.112.37	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 16:32:15.43848+00
117	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 08:10:07.549983+00
121	103.197.112.37	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:20:05.643817+00
125	103.197.112.37	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:20:58.392203+00
118	103.197.113.192	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 08:13:37.712355+00
123	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:20:40.311441+00
128	unknown	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 14:21:33.848871+00
130	103.197.112.37	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 14:21:43.850364+00
119	103.197.113.192	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-10-19 08:14:33.772636+00
120	103.197.112.37	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:01:41.944706+00
122	103.197.112.37	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:20:36.178843+00
124	103.197.112.37	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-19 14:20:45.691992+00
127	103.197.112.37	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 14:21:26.651427+00
129	unknown	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 14:21:35.377381+00
131	103.197.112.37	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-19 14:53:51.941079+00
133	103.197.112.37	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-19 20:55:40.955221+00
134	49.44.122.40	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36	India	Mumbai	Maharashtra	19.0167	72.85	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760969943749_4o24fn1lv	\N	\N	mobile	Chrome	Linux	f	2025-10-20 14:19:56.2076+00
135	49.44.76.70	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36	India	Mumbai	Maharashtra	19.0167	72.85	Asia/Kolkata	en-US	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760969942901_ttr1afm9k	\N	\N	mobile	Chrome	Linux	f	2025-10-20 14:19:59.335104+00
136	157.51.147.156	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-21 14:46:37.043493+00
137	157.51.147.156	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 14:46:41.218671+00
138	157.51.147.156	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 14:46:44.159049+00
139	157.51.147.156	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 14:46:46.664745+00
140	157.51.147.146	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 15:28:23.620609+00
141	157.51.147.146	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 15:28:26.374779+00
142	157.51.147.146	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-21 15:45:29.691993+00
143	103.208.230.82	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-21 19:06:44.27073+00
144	103.208.230.82	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-21 19:07:04.207847+00
145	103.208.230.82	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-21 19:15:30.737251+00
146	103.208.230.79	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:46:37.598583+00
147	103.208.230.79	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:46:37.896507+00
148	103.208.230.79	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:46:39.570327+00
149	103.208.230.79	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:46:49.250193+00
150	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:51:15.319553+00
151	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:51:32.953206+00
152	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:52:35.368492+00
154	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:55:55.382665+00
153	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://127.0.0.1:5502/frontend/pages/index.html	http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:53:22.49063+00
156	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:56:15.477956+00
155	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:55:58.33612+00
157	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-6rzp8m3mo-gowshik-projects.vercel.app/	https://ocean-sentinels-6rzp8m3mo-gowshik-projects.vercel.app/pages/index.html	session_1761108976942_2qt7ktbye	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:57:58.614251+00
158	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:58:13.495119+00
159	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:58:16.052063+00
160	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-6rzp8m3mo-gowshik-projects.vercel.app/	https://ocean-sentinels-6rzp8m3mo-gowshik-projects.vercel.app/pages/index.html	session_1761108976942_2qt7ktbye	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:58:17.920706+00
161	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:58:17.903189+00
162	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761109110647_jw1gwxav7	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:58:54.35391+00
163	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1761109110647_jw1gwxav7	\N	\N	desktop	Chrome	Windows	f	2025-10-22 04:59:12.440689+00
164	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:05:55.564335+00
165	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:04.744541+00
166	117.196.152.98	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761109554066_pls17o8vq	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:09.796092+00
167	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:16.015265+00
168	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:46.16972+00
169	103.208.231.19	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:47.683994+00
170	182.79.253.133	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36	India	Washermanpet	Tamil Nadu	13.1294	80.2864	Asia/Kolkata	en-GB	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761109607974_ji00c9m10	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:57.384642+00
171	117.196.152.98	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761109554066_pls17o8vq	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:06:59.15261+00
172	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1761109554066_pls17o8vq	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:07:05.884779+00
173	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:07:25.809406+00
174	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:08:03.164029+00
175	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:08:56.474495+00
176	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:09:03.153442+00
177	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:09:10.039371+00
179	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:10:09.549645+00
180	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/admin-dashboard.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:10:23.326425+00
183	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/my-reports.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html#report-hazard	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:11:02.119493+00
178	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:10:06.901187+00
184	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:11:09.600033+00
181	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/admin-dashboard.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:10:26.125757+00
182	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/my-reports.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/analytics.html	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:10:40.840607+00
185	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/my-reports.html	https://ocean-sentinels-hux2hgrxb-gowshik-projects.vercel.app/pages/index.html#report-hazard	session_1761109800955_a5z8gbbno	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:11:30.794588+00
186	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:00.711702+00
187	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:05.183407+00
188	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:05.852427+00
189	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:09.232485+00
190	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:14.32832+00
191	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:15.8288+00
192	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:17.435407+00
193	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:21.129263+00
194	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:21.965521+00
195	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:22.959828+00
196	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:26.45728+00
197	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:27.721931+00
198	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:28.843304+00
199	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN		http://127.0.0.1:5502/frontend/pages/index.html	session_1761108670776_sopwk19so	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:13:29.695462+00
200	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/pages/index.html	session_1761110076425_uw69cnkfa	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:14:43.354901+00
201	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/pages/index.html	session_1761110076425_uw69cnkfa	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:14:45.468726+00
202	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/	https://ocean-sentinels-1udhbsmx3-gowshik-projects.vercel.app/pages/index.html	session_1761110076425_uw69cnkfa	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:15:15.445139+00
203	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:15:19.517721+00
204	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:15:22.290095+00
501	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:35.520997+00
205	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761110148613_0buh5ybug	\N	\N	desktop	Chrome	Windows	f	2025-10-22 05:15:55.879713+00
206	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	12.7192376	79.9975916	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-22 06:08:55.334358+00
207	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:44:41.515042+00
208	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:44:47.582475+00
209	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:44:50.861034+00
210	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:45:03.855554+00
211	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:45:07.799182+00
212	103.208.230.74	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-23 05:45:10.60089+00
213	157.49.104.147	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761212286896_tspqyfy22	\N	\N	mobile	Chrome	Linux	f	2025-10-23 09:38:11.438525+00
214	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:47:33.402528+00
215	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:57:08.737317+00
216	103.104.124.164	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:57:10.197935+00
217	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:57:37.66501+00
218	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:57:46.505258+00
219	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:57:54.808693+00
220	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 18:58:02.855486+00
221	103.104.124.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:02:58.370025+00
222	103.104.124.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:22.048076+00
223	103.104.124.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:26.17248+00
224	103.104.124.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:30.237607+00
225	103.104.124.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:31.132422+00
232	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:35:26.445198+00
238	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332676297_idz4uc7ap	\N	\N	desktop	Chrome	Windows	f	2025-10-24 20:00:55.736197+00
226	182.79.253.141	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	New Delhi	National Capital Territory of Delhi	28.6327	77.2198	Asia/Kolkata	en-US	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1761332602009_15jg3ou8d	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:32.213463+00
231	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:34:26.212767+00
233	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:35:29.391808+00
235	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:38:55.504877+00
236	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:56:03.382195+00
227	42.106.160.198	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36	India	Ālangulam	Tamil Nadu	8.8614	77.5049	Asia/Kolkata	en-US	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332608612_hu55fgerp	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:03:39.033333+00
228	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332676297_idz4uc7ap	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:04:40.82815+00
229	103.197.113.143	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332676297_idz4uc7ap	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:17:58.733569+00
230	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:34:22.586924+00
234	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:35:33.784193+00
237	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-24 19:56:21.422544+00
239	34.72.176.129	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/125.0.6422.60 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761381890595_e5n5m063c	\N	\N	desktop	Chrome	Linux	t	2025-10-25 08:44:51.333017+00
240	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:27:35.438694+00
241	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:28:03.247992+00
242	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:28:13.591707+00
243	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:36:54.611765+00
244	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:37:14.320545+00
245	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:37:18.639761+00
246	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:37:53.717596+00
247	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 04:38:06.156364+00
248	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 10:38:50.904799+00
249	103.208.230.78	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-26 17:00:35.004992+00
250	103.208.230.78	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-26 17:00:51.997965+00
251	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:52:25.80617+00
252	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:52:27.092363+00
253	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:52:37.619144+00
254	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:52:45.91569+00
261	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:55:00.49424+00
269	157.51.151.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 14:04:12.722473+00
272	157.51.151.81	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:03:28.326957+00
275	117.55.240.69	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Ghaziabad	Uttar Pradesh	28.6667	77.4333	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761584620392_598dx24ol	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:04:04.810102+00
281	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:02:05.309693+00
255	120.138.12.56	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:53:15.236921+00
258	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:54:40.277173+00
262	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:55:28.356007+00
266	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 18:06:23.624851+00
274	49.44.87.171	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Nangloi Jat	Delhi	28.672	77.0637	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761584592731_lii5b8edq	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:03:32.451796+00
278	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:04:32.446562+00
282	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:02:26.327451+00
283	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:02:30.429836+00
256	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:54:24.595795+00
260	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:54:43.882016+00
263	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:57:02.437833+00
264	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:57:04.795391+00
267	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 18:06:29.545196+00
273	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:03:30.186182+00
276	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:04:21.147446+00
257	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:54:30.602362+00
259	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:54:42.193449+00
265	103.208.230.78	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-26 17:57:48.392198+00
268	103.104.124.163	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-10-26 18:06:49.091653+00
270	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:03:00.168061+00
271	49.44.86.196	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36	India	Nangloi Jat	Delhi	28.672	77.0637	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1761584593318_v86e4rm6a	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:03:27.026455+00
277	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:04:23.467741+00
279	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 17:05:55.781174+00
280	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:01:58.515682+00
284	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:02:35.533487+00
285	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1761588158808_i3strn9yf	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:02:45.727986+00
286	157.51.17.77	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Molasur	Tamil Nadu	12.18806	79.69077	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:03:04.353799+00
287	1.38.102.144	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-27 18:03:05.813099+00
288	103.208.231.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-28 17:04:10.379881+00
289	103.208.231.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-28 17:04:18.734494+00
290	103.208.231.6	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-28 18:33:26.831234+00
291	103.208.231.6	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-28 18:33:37.759519+00
292	103.208.231.6	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-28 18:33:52.062932+00
293	103.208.231.6	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-28 18:34:16.046167+00
294	103.208.231.6	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-28 18:35:15.594674+00
295	103.208.231.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-29 08:23:41.601824+00
296	103.208.231.6	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-29 08:23:59.137805+00
297	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-29 08:24:19.461395+00
298	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-29 08:24:20.774097+00
300	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-30 15:38:06.83305+00
301	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-30 15:38:22.313122+00
309	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-11-01 03:51:40.302177+00
310	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-11-01 03:51:53.286208+00
317	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:20:18.230206+00
323	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:25.541512+00
326	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#about-us	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:46.231104+00
331	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:58:38.93175+00
338	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 13:03:17.76197+00
339	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 13:03:22.076336+00
340	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 13:03:23.384884+00
343	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:31:07.315748+00
347	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/admin-dashboard.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:34:55.597837+00
299	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-29 08:25:34.117361+00
302	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-10-30 15:40:31.458527+00
303	103.208.230.128	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-30 16:34:20.99603+00
304	103.208.230.128	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-30 16:55:41.321963+00
305	157.51.150.189	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-10-31 10:06:49.633677+00
306	117.196.153.109	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-31 15:58:23.082571+00
307	117.196.153.109	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-10-31 15:58:40.837221+00
308	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-11-01 03:51:30.282711+00
311	117.196.153.109	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Puducherry	Union Territory of Puducherry	11.9327	79.8339	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-11-01 03:52:46.94986+00
312	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-11-01 03:52:53.725755+00
313	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:19:56.09616+00
314	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:19:58.94086+00
315	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:20:10.700106+00
316	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:20:12.808324+00
318	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-01 06:20:37.370745+00
319	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:07.314996+00
320	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#about-us	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:10.584579+00
321	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:13.407998+00
322	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:25.215913+00
324	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#report-hazard	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:38.534673+00
325	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#about-us	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:42.424476+00
327	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:57:59.761627+00
328	unknown	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:58:01.401073+00
330	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:58:31.822865+00
332	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:58:42.235181+00
333	157.51.12.14	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 12:58:47.320039+00
334	157.51.12.14	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 12:58:49.86254+00
335	157.51.12.14	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 12:58:56.271105+00
337	103.208.230.128	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 13:03:16.271717+00
329	157.51.12.14	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Madurai	Tamil Nadu	9.921	78.0063	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1762001821380_y6k4jta6t	\N	\N	mobile	Chrome	Linux	f	2025-11-01 12:58:26.323129+00
342	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:31:04.602515+00
344	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:31:16.474597+00
346	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:34:53.668548+00
348	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:35:08.094543+00
336	157.51.12.14	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1762001821380_y6k4jta6t	\N	\N	desktop	Chrome	Linux	f	2025-11-01 12:59:10.478617+00
341	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:31:02.388151+00
345	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:34:48.911554+00
349	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-02 17:40:02.210358+00
350	103.208.230.128	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		http://localhost:3000/frontend/pages/index.html	session_1762105210289_gw928q98h	\N	\N	desktop	Edge	Windows	f	2025-11-02 17:40:19.773711+00
351	120.138.12.240	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-03 15:33:11.796107+00
352	120.138.12.240	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-03 15:33:14.541487+00
353	120.138.12.240	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-03 15:33:26.317809+00
354	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762260455889_jjq0rhp03	\N	\N	desktop	Chrome	Windows	f	2025-11-04 12:47:46.044038+00
355	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762260455889_jjq0rhp03	\N	\N	desktop	Chrome	Windows	f	2025-11-04 12:48:37.634947+00
356	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762260529122_x2vp8nfum	\N	\N	desktop	Edge	Windows	f	2025-11-04 12:48:52.020354+00
357	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 12:53:20.150109+00
358	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 12:53:24.306209+00
359	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 12:53:53.236916+00
360	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:00:36.169172+00
361	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:00:41.661959+00
362	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:01:34.80241+00
363	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:02:43.71645+00
364	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:02:46.658528+00
365	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/my-reports.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:03:25.841148+00
366	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/analytics.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:03:27.759681+00
502	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:36.431413+00
367	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/analytics.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:04:15.374173+00
374	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:17.213451+00
381	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137442	79.6485848	\N	en-IN	http://localhost:3000/frontend/pages/my-reports.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 14:03:29.97813+00
383	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/analytics.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 14:03:58.099668+00
385	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:14.282871+00
389	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:23.879036+00
410	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137439	79.6485852	\N	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:45.257144+00
416	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:07:07.953867+00
368	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:18:56.183306+00
369	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:19:40.727598+00
370	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:19:44.272777+00
373	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:14.949151+00
376	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/analytics.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:30.035135+00
378	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/analytics.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:26:55.575409+00
380	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/analytics.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 14:03:11.89509+00
382	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN	http://localhost:3000/frontend/pages/public-analytics.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 14:03:57.4738+00
386	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:15.784358+00
396	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:52.358408+00
409	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137439	79.6485852	\N	en-IN	http://localhost:3000/frontend/pages/authority-analytics.html	http://localhost:3000/frontend/pages/index.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:41.705504+00
412	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:05:59.425578+00
415	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:06:55.766577+00
371	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/my-reports.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:02.448072+00
375	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:20.108968+00
387	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:20.44906+00
390	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:24.997555+00
391	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:26.225911+00
392	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:30.584161+00
393	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:31.905779+00
394	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:33.212527+00
395	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:34.428327+00
398	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/my-reports.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:04.193551+00
400	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:06.942312+00
402	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:09.665547+00
404	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:12.370415+00
406	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:15.068102+00
408	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN	http://localhost:3000/frontend/pages/reports.html	http://localhost:3000/frontend/pages/analytics.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:28.477777+00
413	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:06:02.864048+00
372	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/my-reports.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:20:12.848937+00
377	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/public-analytics.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 13:26:54.483194+00
379	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 14:03:07.346077+00
384	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:09.015394+00
388	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:22.502621+00
397	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:01:54.358362+00
399	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:05.573505+00
401	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:08.307636+00
403	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:11.016294+00
405	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:13.701078+00
407	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485836	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:02:16.43309+00
411	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN	http://localhost:3000/frontend/pages/reports.html	http://localhost:3000/frontend/pages/analytics.html	session_1762268502644_cvjii4e25	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:03:14.804238+00
414	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.9137431	79.6485857	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:06:32.143624+00
417	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.913743	79.648586	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:08:09.364329+00
418	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762268902107_r35raopuw	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:08:31.188473+00
419	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.913743	79.648586	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:08:45.873172+00
420	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:10:52.364621+00
421	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762268750361_tjsu9dc50	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:12:25.897659+00
422	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:13:16.228146+00
423	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:14:03.433195+00
424	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.1271225	78.6568942	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:14:10.151258+00
425	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	\N	\N	\N	11.913774307453698	79.64796528209105	\N	en-US	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1762269282813_r6tiv5in7	\N	\N	desktop	Edge	Windows	f	2025-11-04 15:14:47.737453+00
426	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	\N	\N	\N	11.913774307453698	79.64796528209105	\N	en-US		http://localhost:3000/frontend/pages/index.html	session_1762269282813_r6tiv5in7	\N	\N	desktop	Edge	Windows	f	2025-11-04 15:15:18.354696+00
427	103.208.230.127	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	11.913743	79.6485853	\N	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-04 15:16:58.843178+00
428	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 14:25:15.794161+00
429	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 14:25:24.08036+00
430	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 15:55:43.499457+00
431	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 15:57:56.52225+00
432	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 15:59:02.946938+00
433	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:00:13.994131+00
434	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:00:39.712095+00
435	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:02:23.659276+00
436	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:03:30.553988+00
437	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:03:37.323002+00
438	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		http://localhost:3000/frontend/pages/index.html	session_1762269282813_r6tiv5in7	\N	\N	desktop	Edge	Windows	f	2025-11-05 16:03:46.224749+00
439	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:07:54.112501+00
440	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:08:04.338554+00
441	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:08:05.697173+00
442	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:08:07.457938+00
443	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		http://localhost:3000/frontend/pages/index.html	session_1762358893101_6wde3gexa	\N	\N	desktop	Edge	Windows	f	2025-11-05 16:08:20.40073+00
444	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:08:37.286256+00
445	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:08:38.680833+00
446	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:10:10.391103+00
447	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:14:46.92885+00
448	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:14:50.160555+00
449	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:14:51.847274+00
450	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:15:20.730586+00
451	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:15:22.08997+00
456	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:33:23.635285+00
475	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:07:53.847254+00
480	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:18:56.54721+00
452	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:29:10.323274+00
463	103.197.112.113	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://gs0s8zcp-3000.inc1.devtunnels.ms/frontend/pages/index.html	session_1762361327159_1nmgr95cx	\N	\N	mobile	Chrome	Linux	f	2025-11-05 16:48:50.587824+00
467	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36 Edg/142.0.0.0	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US		http://localhost:3000/frontend/pages/	session_1762361853215_1392cg6xh	\N	\N	desktop	Edge	Windows	f	2025-11-05 16:57:40.642495+00
470	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137439	79.648585	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:05:48.143658+00
473	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:07:32.448803+00
476	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:08:45.690705+00
481	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:19:01.48167+00
484	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:20:26.664864+00
453	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:30:09.294866+00
455	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:32:35.607653+00
458	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:35:16.230726+00
461	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/index.html	http://localhost:3000/frontend/pages/admin-dashboard.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:45:02.403495+00
464	103.197.112.113	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	11.9137422	79.6485831	Asia/Kolkata	en-IN		https://gs0s8zcp-3000.inc1.devtunnels.ms/frontend/pages/index.html	session_1762361327159_1nmgr95cx	\N	\N	mobile	Chrome	Linux	f	2025-11-05 16:48:58.863671+00
471	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137439	79.648585	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:06:44.840417+00
474	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:07:36.218556+00
477	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:08:54.767628+00
482	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:19:03.878599+00
485	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:22:59.261413+00
487	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:24:44.729572+00
454	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:31:27.957989+00
459	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:35:27.175015+00
462	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137427	79.6485863	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:46:03.291359+00
465	103.197.112.113	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	11.9137417	79.6485801	Asia/Kolkata	en-IN		https://gs0s8zcp-3000.inc1.devtunnels.ms/frontend/pages/index.html	session_1762361327159_1nmgr95cx	\N	\N	mobile	Chrome	Linux	f	2025-11-05 16:52:38.163977+00
466	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:53:01.338177+00
478	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:09:06.554589+00
457	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:35:04.57425+00
460	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 16:44:50.554241+00
468	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137431	79.6485841	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:01:24.731786+00
469	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:03:44.198956+00
472	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	http://localhost:3000/frontend/pages/admin-dashboard.html	http://localhost:3000/frontend/pages/index.html	session_1760638276707_hmiai6uhp	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:07:30.238967+00
479	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137431	79.6485823	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:10:51.450834+00
483	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:20:21.184625+00
486	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:23:11.656374+00
488	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:03.82969+00
489	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:05.156954+00
490	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:13.222372+00
491	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:15.457345+00
492	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:44.943428+00
493	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:46.298629+00
494	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:25:47.667704+00
495	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html#	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:26:46.313686+00
496	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/	session_1762361156249_6ws59r9xf	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:29:27.496945+00
497	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:32:44.712519+00
498	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN		http://localhost:3000/frontend/pages/index.html#about-us	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:34:12.928032+00
499	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	https://ocean-sentinels-nr8rig4yp-gowshik-projects.vercel.app/	https://ocean-sentinels-nr8rig4yp-gowshik-projects.vercel.app/pages/index.html	session_1762364114890_11bwjbu38	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:35:21.997697+00
500	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	https://ocean-sentinels-nr8rig4yp-gowshik-projects.vercel.app/	https://ocean-sentinels-nr8rig4yp-gowshik-projects.vercel.app/pages/index.html	session_1762364114890_11bwjbu38	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:35:26.015317+00
503	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:36.899737+00
505	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:38.79665+00
516	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:43.811066+00
525	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:17.447044+00
530	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:24.211961+00
535	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:29.613752+00
538	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:31.287912+00
545	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:36.500182+00
548	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:38.083549+00
550	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:39.234134+00
551	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:40.644413+00
556	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:44.220341+00
558	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:45.824763+00
504	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:36.939023+00
506	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:39.170576+00
508	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:39.970354+00
511	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:40.928626+00
520	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:50.564991+00
522	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:52.989903+00
529	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:22.884675+00
539	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:32.384374+00
542	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:34.014457+00
552	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:40.83908+00
554	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:41.993525+00
507	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:39.5139+00
509	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:40.163239+00
517	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:44.133199+00
518	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:45.043469+00
521	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:51.894595+00
523	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:16.105562+00
528	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:21.550525+00
533	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:28.247126+00
536	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:29.938404+00
543	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:35.127298+00
546	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:36.722786+00
560	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:47.20973+00
510	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:40.91959+00
512	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:40.597795+00
515	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:42.761751+00
519	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:45.365627+00
524	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:16.474815+00
526	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:18.811332+00
527	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:20.178503+00
531	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:25.561872+00
532	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:26.891352+00
534	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0717	80.2556	Asia/Kolkata	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:28.594448+00
537	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:31.018815+00
540	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:32.653335+00
541	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:33.752852+00
544	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:35.371423+00
547	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:37.864576+00
549	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:39.126406+00
553	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:41.021205+00
555	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:43.336318+00
557	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:44.68044+00
559	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html#	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:46.031015+00
561	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:37:48.581071+00
513	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:41.43886+00
514	103.104.124.175	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US		https://sih.vortexinfinite.xyz/pages/index.html	session_1761332224281_g2dga8end	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:36:42.112288+00
562	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:38:09.372353+00
563	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:38:11.25722+00
564	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:38:12.69607+00
565	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137442	79.6485766	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:40:26.414407+00
566	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137442	79.6485766	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:40:28.912734+00
567	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137442	79.6485766	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:40:55.567268+00
568	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:42:12.997368+00
569	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:42:23.957085+00
570	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html#	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:43:08.965482+00
571	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.7192376	79.9975916	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:43:48.843373+00
572	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:47:35.231934+00
573	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:47:37.7324+00
574	103.197.112.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN		http://localhost:3000/frontend/pages/index.html	session_1762362532764_sqtzwz7s3	\N	\N	desktop	Chrome	Windows	f	2025-11-05 17:48:06.883878+00
575	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137433	79.648581	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:04:42.751222+00
576	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137433	79.648581	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:04:45.563626+00
577	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.1271225	78.6568942	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:04:53.77428+00
578	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.1271225	78.6568942	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/visitor_details.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:05:38.764188+00
579	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.1271225	78.6568942	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:05:40.017887+00
580	120.138.12.113	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137433	79.648581	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-06 13:06:09.354691+00
581	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:57:13.103956+00
582	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:57:14.263501+00
583	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/my-reports.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:57:30.724052+00
584	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/analytics.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:57:33.533239+00
585	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:57:46.988701+00
586	103.208.230.142	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.9137428	79.6485865	Asia/Kolkata	en-IN	https://www.google.com/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-07 10:58:15.72136+00
587	66.249.79.133	Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/141.0.7390.122 Safari/537.36	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762588918686_n0ja7c6z2	\N	\N	desktop	Chrome	unknown	t	2025-11-08 08:02:24.438315+00
588	66.249.79.133	Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.7390.122 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)	\N	\N	\N	\N	\N	\N	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1762588920643_n0ja7c6z2	\N	\N	mobile	Chrome	Linux	t	2025-11-08 08:02:27.798403+00
589	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	11.913744	79.6485761	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-11 18:41:35.066449+00
590	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/admin-dashboard.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-11 18:41:47.476158+00
591	103.208.230.34	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/pages/analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-11-12 15:31:15.31434+00
592	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:16:03.096935+00
593	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:16:06.866148+00
594	unknown	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	\N	\N	\N	\N	\N	\N	en-IN	https://sih.vortexinfinite.xyz/pages/index.html	https://sih.vortexinfinite.xyz/pages/index.html#about-us	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:16:12.827537+00
595	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:16:41.448571+00
596	103.208.230.34	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760770080337_kxdfudm3h	\N	\N	desktop	Chrome	Linux	f	2025-11-12 16:16:50.504415+00
597	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:16:57.757058+00
598	103.208.230.34	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.6819372	79.9888413	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-12 16:36:58.728874+00
599	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Tirupati	Andhra Pradesh	13.6409	79.4192	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1763014143839_kgcnfkjqc	\N	\N	desktop	Chrome	Windows	f	2025-11-13 06:09:16.016923+00
600	117.250.229.185	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Tirupati	Andhra Pradesh	11.9177216	79.6360704	Asia/Kolkata	en-US	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1763014143839_kgcnfkjqc	\N	\N	desktop	Chrome	Windows	f	2025-11-13 06:27:03.903675+00
601	103.208.230.40	Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	desktop	Chrome	Linux	f	2025-11-16 17:34:31.248654+00
602	103.208.231.228	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.2307724	79.0758037	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-23 08:27:00.435181+00
603	103.208.231.228	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.2307724	79.0758037	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-23 08:27:02.608539+00
604	103.208.231.228	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.2307724	79.0758037	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-23 08:27:27.531659+00
605	103.208.231.228	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.2307724	79.0758037	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-23 08:27:34.075536+00
606	103.208.231.228	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36	India	Chennai	Tamil Nadu	12.2307724	79.0758037	Asia/Kolkata	en-IN		https://sih.vortexinfinite.xyz/pages/index.html	session_1760720213600_4balzhz3g	\N	\N	desktop	Chrome	Windows	f	2025-11-23 19:22:49.001044+00
607	103.197.112.100	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-11-25 16:10:56.021485+00
608	103.197.112.100	Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36	India	Chennai	Tamil Nadu	13.0895	80.2739	Asia/Kolkata	en-IN	https://sih.vortexinfinite.xyz/pages/public-analytics.html	https://sih.vortexinfinite.xyz/pages/index.html	session_1760768164237_1vu3gm311	\N	\N	mobile	Chrome	Linux	f	2025-11-25 16:21:26.452548+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.users (id, username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified, created_at, updated_at, last_login) FROM stdin;
1	dev.gowshiks@gmail.com	dev.gowshiks@gmail.com	$2b$12$5wYDtEnoDV7X1Q.udj5MrO5wokcPdohJ/oHrELqd/J/a78uTljCXy	Gowshik	S	8270288569	east-coast	PUBLIC	t	f	2025-10-10 19:04:40.801265+00	2025-10-10 19:04:41.834403+00	2025-10-10 13:34:41.638245+00
10	oceanadmin	admin@oceanguard.gov.in	240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9	Ocean	Administrator	1800-123-4567	New Delhi - Ministry of Earth Sciences	ADMIN	t	f	2025-10-14 13:26:24.323912+00	2025-10-14 15:07:20.446501+00	2025-10-14 15:07:20.774532+00
13	testuser_1760454468	test1760454468@example.com	7e6e0c3079a08c5cc6036789b57e951f65f82383913ba1a49ae992544f1b4b6e	Test	User	1234567890	test-location	PUBLIC	t	f	2025-10-14 15:07:50.535677+00	\N	\N
14	testuser_1760454590	test1760454590@example.com	7e6e0c3079a08c5cc6036789b57e951f65f82383913ba1a49ae992544f1b4b6e	Test	User	1234567890	test-location	PUBLIC	t	f	2025-10-14 15:09:53.049712+00	\N	\N
15	testuser_1760454605	test1760454605@example.com	7e6e0c3079a08c5cc6036789b57e951f65f82383913ba1a49ae992544f1b4b6e	Test	User	1234567890	test-location	PUBLIC	t	f	2025-10-14 15:10:08.004685+00	\N	\N
16	testuser_1760454674	test1760454674@example.com	7e6e0c3079a08c5cc6036789b57e951f65f82383913ba1a49ae992544f1b4b6e	Test	User	1234567890	test-location	PUBLIC	t	f	2025-10-14 15:11:16.811652+00	\N	\N
17	testuser_1760454930	test1760454930@example.com	7e6e0c3079a08c5cc6036789b57e951f65f82383913ba1a49ae992544f1b4b6e	Test	User	1234567890	test-location	PUBLIC	t	f	2025-10-14 15:15:33.1146+00	\N	\N
19	test3@gmail.com	test3@gmail.com	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	test	3	568	andaman	PUBLIC	t	f	2025-10-14 16:31:54.710482+00	2025-10-14 16:31:57.900825+00	2025-10-14 16:31:58.227576+00
4	sih25@gmail.com	sih25@gmail.com	$2b$12$8/VBtxupcLpGQ1XTM67XTumEjtS/Xs1W1IahUpiQT1wunDUKvhJ4.	SIH	25	987456321	west-coast	PUBLIC	t	f	2025-10-10 20:13:54.751031+00	2025-10-10 20:13:55.222667+00	2025-10-10 14:43:54.921328+00
20	tn@gmail.com	tn@gmail.com	4da8455b63261516e682ece76dcbd68a1abf3598141193974aa069f3ad1cc9d0	rescue_tn		7895566866	Tamilnadu	RESCUE_TEAM	t	f	2025-10-14 16:37:33.397913+00	2025-10-15 18:11:15.422899+00	2025-10-15 18:11:15.750542+00
3	deva@vi.com	deva@vi.com	$2b$12$ATgvLWJhgXlkb3n9c6.R4OEA5hzgJiJUqsj3xXw2Hwl0frhNgJ8Kq	rescue_py		987654321	Pondicherry	RESCUE_TEAM	t	f	2025-10-10 20:05:44.122376+00	2025-10-11 18:29:25.774588+00	2025-10-11 12:59:24.318434+00
6	rohansta104@gmail.com	rohansta104@gmail.com	$2b$12$tnRYtEP0wUUegM/mz7IIy.dkkbxigmPuDcYJifdK.nbPkJYViX20m	Rohan	C	987456215	west-coast	PUBLIC	t	f	2025-10-12 20:51:49.08042+00	2025-10-12 20:51:49.991679+00	2025-10-12 15:21:49.957048+00
2	OceanAdmin	admin@vi.com	$2b$12$oJPjolj2/QrPCv.EcEkUAOle04Sjgp.WyQQFKmx82lslb/N7JEk4G	Ocean	Administrator	\N	\N	ADMIN	t	t	2025-10-10 19:22:15.701332+00	2025-10-12 21:32:33.468329+00	2025-10-12 16:02:33.263323+00
7	john12@test.com	john12@test.com	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	John 	Cq	45698774	west-coast	PUBLIC	t	f	2025-10-13 22:38:48.056899+00	\N	\N
8	string	user@example.com	473287f8298dba7163a897908958f7c0eae733e25d2e027992ea2edc9bed2fa8	string	string	string	string	PUBLIC	t	f	2025-10-13 22:39:38.299218+00	\N	\N
9	asdsad@sadad.mdasd	asdsad@sadad.mdasd	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	sdsadas	asdasd	1654365416	east-coast	PUBLIC	t	f	2025-10-14 12:36:39.232731+00	\N	\N
25	tnauth@gmail.com	tnauth@gmail.com	4da8455b63261516e682ece76dcbd68a1abf3598141193974aa069f3ad1cc9d0	TN_Auth		78454958666	Admin	AUTHORITY	t	f	2025-10-15 18:23:39.212064+00	2025-10-15 18:24:32.698857+00	2025-10-15 18:24:33.027301+00
12	test2@gmail.com	test2@gmail.com	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	test	2	789654123	west-coast	PUBLIC	t	f	2025-10-14 15:03:14.743353+00	\N	\N
11	test1@gmail.com	test1@gmail.com	8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92	Test	1	987456321	east-coast	PUBLIC	t	f	2025-10-14 13:27:27.227779+00	2025-10-16 00:44:46.622557+00	2025-10-16 00:44:46.951367+00
27	sihrescue@vi.com	sihrescue@vi.com	4da8455b63261516e682ece76dcbd68a1abf3598141193974aa069f3ad1cc9d0	SIH_RESCUE		987654321	INDIA	RESCUE_TEAM	t	f	2025-10-16 00:24:21.3194+00	2025-11-04 15:02:17.879449+00	2025-11-04 15:02:18.203596+00
29	sihcitizen@vi.com	sihcitizen@vi.com	5ee9957a66e6a48de9939c7fc778946729ebe156c0eba4e7c379836f4c278d8d	SIH	25	4654168454	west-coast	PUBLIC	t	f	2025-10-18 06:37:06.090151+00	2025-11-05 16:46:15.438505+00	2025-11-05 16:46:15.764952+00
28	citizensih@vi.comm	citizensih@vi.comm	5ee9957a66e6a48de9939c7fc778946729ebe156c0eba4e7c379836f4c278d8d	SIH	25	316465464	east-coast	PUBLIC	t	f	2025-10-18 06:36:05.443626+00	2025-10-18 06:36:08.642436+00	2025-10-18 06:36:08.978594+00
18	OceanAdmin1	oceanadmin1@oceanguard.gov.in	8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918	Ocean	Admin	1800-123-4567	New Delhi - Ministry of Earth Sciences	ADMIN	t	f	2025-10-14 15:23:29.107535+00	2025-11-11 18:41:40.565429+00	2025-11-11 18:41:41.155673+00
\.


--
-- Data for Name: website_stats; Type: TABLE DATA; Schema: public; Owner: admindb
--

COPY public.website_stats (id, date, total_visits, unique_visitors, page_views, bounce_rate, avg_session_duration, top_countries, top_pages, device_breakdown, created_at) FROM stdin;
\.


--
-- Name: analytics_snapshots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.analytics_snapshots_id_seq', 1, false);


--
-- Name: incidents_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.incidents_id_seq', 19, true);


--
-- Name: system_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.system_metrics_id_seq', 1, false);


--
-- Name: user_visits_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.user_visits_id_seq', 608, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.users_id_seq', 29, true);


--
-- Name: website_stats_id_seq; Type: SEQUENCE SET; Schema: public; Owner: admindb
--

SELECT pg_catalog.setval('public.website_stats_id_seq', 1, false);


--
-- Name: analytics_snapshots analytics_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.analytics_snapshots
    ADD CONSTRAINT analytics_snapshots_pkey PRIMARY KEY (id);


--
-- Name: incidents incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_pkey PRIMARY KEY (id);


--
-- Name: system_metrics system_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.system_metrics
    ADD CONSTRAINT system_metrics_pkey PRIMARY KEY (id);


--
-- Name: user_visits user_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.user_visits
    ADD CONSTRAINT user_visits_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: website_stats website_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.website_stats
    ADD CONSTRAINT website_stats_pkey PRIMARY KEY (id);


--
-- Name: ix_analytics_snapshots_date; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_analytics_snapshots_date ON public.analytics_snapshots USING btree (date);


--
-- Name: ix_analytics_snapshots_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_analytics_snapshots_id ON public.analytics_snapshots USING btree (id);


--
-- Name: ix_incidents_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_incidents_id ON public.incidents USING btree (id);


--
-- Name: ix_incidents_reference_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE UNIQUE INDEX ix_incidents_reference_id ON public.incidents USING btree (reference_id);


--
-- Name: ix_system_metrics_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_system_metrics_id ON public.system_metrics USING btree (id);


--
-- Name: ix_system_metrics_metric_name; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_system_metrics_metric_name ON public.system_metrics USING btree (metric_name);


--
-- Name: ix_user_visits_created_at; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_user_visits_created_at ON public.user_visits USING btree (created_at);


--
-- Name: ix_user_visits_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_user_visits_id ON public.user_visits USING btree (id);


--
-- Name: ix_user_visits_ip_address; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_user_visits_ip_address ON public.user_visits USING btree (ip_address);


--
-- Name: ix_user_visits_session_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_user_visits_session_id ON public.user_visits USING btree (session_id);


--
-- Name: ix_user_visits_user_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_user_visits_user_id ON public.user_visits USING btree (user_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: admindb
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: admindb
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: ix_website_stats_date; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_website_stats_date ON public.website_stats USING btree (date);


--
-- Name: ix_website_stats_id; Type: INDEX; Schema: public; Owner: admindb
--

CREATE INDEX ix_website_stats_id ON public.website_stats USING btree (id);


--
-- Name: incidents incidents_reporter_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES public.users(id);


--
-- Name: incidents incidents_verified_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: admindb
--

ALTER TABLE ONLY public.incidents
    ADD CONSTRAINT incidents_verified_by_id_fkey FOREIGN KEY (verified_by_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

\unrestrict cwidXu5O4xkeSqyk7M2tyvSz8rXbYa4SNrOg9ZwoOHcMA8PUMVbfuhYRbIUr5Qg

