-- create movies table
create table movies (
    id integer primary key generated always as identity,
    title text,
    original_title text,
    tagline text,
    overview text
);

-- create search column
alter table public.movies
add column search_vector tsvector generated always as (
    setweight(to_tsvector('simple', coalesce(public.movies.title, '')), 'A')
    || ' ' ||
	setweight(to_tsvector('simple', coalesce(public.movies.original_title, '')), 'A')
    || ' ' ||
	setweight(to_tsvector('simple', coalesce(public.movies.tagline, '')), 'B')
    || ' ' ||
	setweight(to_tsvector('simple', coalesce(public.movies.overview, '')), 'B') :: tsvector
) stored;

-- create GIN index on seach column
create index idx_movie_search on public.movies using gin(search_vector);

-- disable sequential scan just in case
-- SET enable_seqscan = OFF;

-- example search query

explain analyse select title, tagline, ts_rank(search_vector, websearch_to_tsquery('hero')) as rank
from public.movies
where search_vector @@ websearch_to_tsquery('hero')
order by rank desc;