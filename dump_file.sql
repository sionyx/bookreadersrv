--
-- PostgreSQL database dump
--

\restrict qcpl3mQjCf6UJVhazUkM9Sxw9Kxa7B9GNFiatrghErSdUrDN3FzBuMxJGQtZcGj

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _fluent_migrations; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public._fluent_migrations (
    id uuid NOT NULL,
    name text NOT NULL,
    batch bigint NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


ALTER TABLE public._fluent_migrations OWNER TO vapor_username;

--
-- Name: authors; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public.authors (
    id uuid NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    photo_url text NOT NULL,
    link text NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.authors OWNER TO vapor_username;

--
-- Name: books; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public.books (
    id uuid NOT NULL,
    section_id uuid,
    author_id uuid NOT NULL,
    title text NOT NULL,
    duration integer NOT NULL,
    media_url text NOT NULL,
    cover_url text NOT NULL,
    text_link text NOT NULL,
    description text NOT NULL,
    create_date timestamp with time zone,
    update_date timestamp with time zone,
    delete_date timestamp with time zone,
    preview_url text,
    publish_date timestamp with time zone,
    template text
);


ALTER TABLE public.books OWNER TO vapor_username;

--
-- Name: sections; Type: TABLE; Schema: public; Owner: vapor_username
--

CREATE TABLE public.sections (
    id uuid NOT NULL,
    section_id uuid,
    name text NOT NULL,
    title text NOT NULL,
    cover_url text NOT NULL,
    text_link text NOT NULL,
    description text NOT NULL,
    template text NOT NULL,
    book_template text
);


ALTER TABLE public.sections OWNER TO vapor_username;

--
-- Data for Name: _fluent_migrations; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public._fluent_migrations (id, name, batch, created_at, updated_at) FROM stdin;
9fe61204-6be3-40bb-9a7b-fa0da10c451e	App.CreateSection	1	2025-01-20 15:13:00.704102+00	2025-01-20 15:13:00.704102+00
1f52d3ed-85cf-4d5f-9e95-cda662b2fc31	App.CreateAuthor	1	2025-01-20 15:13:00.727707+00	2025-01-20 15:13:00.727707+00
bc48c4a3-451d-45f9-ba00-d1991fc51d3f	App.CreateBook	1	2025-01-20 15:13:00.771782+00	2025-01-20 15:13:00.771782+00
cba699d8-c005-4876-b503-bcbb11236c17	App.UpdateBook1	2	2025-03-26 12:52:17.185659+00	2025-03-26 12:52:17.185659+00
8beaf157-0610-46d9-9914-83613fbb2d67	App.UpdateSection1	2	2025-03-26 12:52:17.224452+00	2025-03-26 12:52:17.224452+00
\.


--
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public.authors (id, first_name, last_name, photo_url, link, description) FROM stdin;
5d32a5dd-f712-4450-9014-0f9637f596be	Роберт	Шекли	https://web.archive.org/web/20070929222309im_/http://www.sheckley.ru/galery/10.jpg	https://ru.wikipedia.org/wiki/%D0%A8%D0%B5%D0%BA%D0%BB%D0%B8,_%D0%A0%D0%BE%D0%B1%D0%B5%D1%80%D1%82	Ро́берт Ше́кли — американский писатель-фантаст, автор нескольких сотен фантастических рассказов и нескольких десятков научно-фантастических романов и повестей. Мастер иронического юмористического рассказа; один из самых оригинальных юмористов научной фантастики.
af4dd970-3234-4581-8300-9175bc999ecc	Анжей	Сапковский	https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Andrzej_Sapkowski_-_Lucca_Comics_and_Games_2015_2.JPG/250px-Andrzej_Sapkowski_-_Lucca_Comics_and_Games_2015_2.JPG	http://www.sapkowski.su/	А́нджей Сапко́вский — польский писатель-фантаст и публицист, автор популярной фэнтези-саги «Ведьмак». Произведения Сапковского изданы на польском, чешском, русском, немецком, испанском, финском, литовском, французском, английском, португальском, болгарском, белорусском, итальянском, шведском, сербском, украинском и китайском языках. По заявлениям издателей, Сапковский входит в пятёрку самых издаваемых авторов Польши.
a19ab7f1-fe0e-4d0f-abd1-ab690cb4267c	Светлана	Браташ	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/bratash.jpeg	https://t.me/pogovorisosvetoy	Психолог Светлана Браташ 
10e3ecfd-6ede-449c-a764-468c1b02052d	Надежда	Тэффи	https://upload.wikimedia.org/wikipedia/commons/2/21/Teffi_Choumoff.jpg	https://ru.wikipedia.org/wiki/%D0%A2%D1%8D%D1%84%D1%84%D0%B8,_%D0%9D%D0%B0%D0%B4%D0%B5%D0%B6%D0%B4%D0%B0_%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B0%D0%BD%D0%B4%D1%80%D0%BE%D0%B2%D0%BD%D0%B0	Наде́жда Алекса́ндровна Тэ́ффи (настоящая фамилия — Лохви́цкая, в замужестве — Бучинская; 9 мая 1872 года, Санкт-Петербург, Российская империя — 6 октября 1952 года, Париж, Франция) — русская писательница и поэтесса, мемуаристка, переводчица, автор таких знаменитых рассказов, как «Демоническая женщина» и «Ке фер». После Октябрьской революции эмигрировала. Сестра поэтессы Мирры Лохвицкой и генерала Николая Лохвицкого, соратника адмирала Колчака. Другие её сёстры были известны как авторы пьес: Елена Лохвицкая и Варвара Лохвицкая.
89f40369-6c12-41dc-b940-a7be69e7aa06	Оксана	Останина	https://bookreader.hb.ru-msk.vkcloud-storage.ru/authors/ostanina/oksana-ostanina_mini.jpg	https://www.litres.ru/author/oksana-ostanina/	Оксана Викторовна Останина. Родилась в 1979 году в Экибастузе (Казахская ССР). Закончила Томский экономико-промышленный техникум по специальности «Государственное управление», студентка 2 курса Херсонского государственного педагогического университета факультета журналистики, копирайтер, эссеист. Литературной деятельностью занимается в свободное время, пишет стихи и прозу. Автор нескольких книг, написанных преимущественно в жанре научной и социальной фантастики. Публикации в газете «Чунский вестник», «Литературная мастерская», журнале «Начало века» и на сайтах «Проза. Ру, ЛитРес, Автор.Тудей».
7f0da457-8291-4d9d-8d31-7153c7a4e71b	Эльдар	Рязанов	https://upload.wikimedia.org/wikipedia/commons/thumb/3/3e/Ryazanov_in_Kazan.jpg/548px-Ryazanov_in_Kazan.jpg	https://eldar-ryazanov.ru/	Эльдар Александрович Рязанов (18 ноября 1927 — 30 ноября 2015) — советский и российский кинорежиссёр, сценарист, актёр, поэт, драматург, телеведущий, педагог, продюсер; народный артист СССР (1984), лауреат Государственной премии СССР (1977) и Государственной премии РСФСР имени братьев Васильевых (1979).
9a936b79-0178-4836-bb05-309fda45a125	Таня	Гуревич	https://bookreader.hb.ru-msk.vkcloud-storage.ru/authors/gurevich/tania_gurevich_mini.jpg	https://www.litres.ru/author/tanya-gurevich-27626786/	
56ef83ad-6d2f-422b-a8c6-726a163d4913	Ив	Ланда	https://bookreader.hb.ru-msk.vkcloud-storage.ru/authors/landa/ivlanda_mini.jpg	https://author.today/u/landaiv	
12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подскаст		https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png		Подскаст про психологию, перфекционизм, самооценку и самоценность.
\.


--
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public.books (id, section_id, author_id, title, duration, media_url, cover_url, text_link, description, create_date, update_date, delete_date, preview_url, publish_date, template) FROM stdin;
5ea6d77d-95e3-441e-a4c6-c26b10a5c0b6	6928c53a-e978-4bca-9287-e46f3c0052f1	9a936b79-0178-4836-bb05-309fda45a125	Цепочка распада	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/cepochka_raspada/cepochka_raspada.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/cepochka_raspada/cepochka_raspada.jpg	https://www.litres.ru/book/tanya-gurevich-27626786/cepochka-raspada-70619701/	В темных закоулках будущего, где технологии и психология сплетаются в опасном тандеме, учёный исследует цепочки распада. Антиутопия-головоломка про мир, в котором мысли – оружие, а влияние – разрушительное топливо, оставляет вас наедине с философской дилеммой: что вообще такое наша реальность?	2025-04-11 08:12:39.435352+00	2025-04-11 11:54:00.37182+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/cepochka_raspada/cepochka_raspada_mini.jpg	1970-01-01 00:00:00+00	
a94473be-ac98-4ead-a81f-6c8837411939	6928c53a-e978-4bca-9287-e46f3c0052f1	89f40369-6c12-41dc-b940-a7be69e7aa06	Патоген	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/patogen/Oksana_ostanina_patogen.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/patogen/patogen.jpg	https://www.litres.ru/audiobook/oksana-ostanina/patogen-70854433/	Карнавальная чума поражает животных. Под угрозой все человечество и планета Земля. Хадис не верит, что город, в котором он поселился, единственный в мире. Слишком много несостыковок. Последней каплей в бочонке неверия становится игуана. Этот мир еще можно спасти.	\N	2025-04-11 22:14:44.402842+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/patogen/%D0%9F%D0%B0%D1%82%D0%BE%D0%B3%D0%B5%D0%BD_mini.png	1970-01-01 00:00:00+00	
8e0edcfb-adee-420e-9c50-5afaa1385d06	6928c53a-e978-4bca-9287-e46f3c0052f1	5d32a5dd-f712-4450-9014-0f9637f596be	Человек по Платону	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/chelovek_po_platonu/%D0%A7%D0%B5%D0%BB%D0%BE%D0%B2%D0%B5%D0%BA%20%D0%BF%D0%BE%20%D0%9F%D0%BB%D0%B0%D1%82%D0%BE%D0%BD%D1%83%20-%20%D0%A0%D0%BE%D0%B1%D0%B5%D1%80%D1%82%20%D0%A8%D0%B5%D0%BA%D0%BB%D0%B8.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/chelovek_po_platonu/chelovek_po_platonu2.jpg		Пока члены экспедиции исследуют планету Регул-V, Холлорен вместе с роботом Максом остается охранять лагерь. Но он еще не представляет к каким последствиям это приведет, ведь Макс, как выясняется, не отличается особым умом и сообразительностью.	\N	2025-04-10 18:38:07.626282+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/chelovek_po_platonu/chelovek_po_platonu2_mini.jpg	1970-01-01 00:00:00+00	
63a78e52-f82c-4281-a031-d889e443a697	6928c53a-e978-4bca-9287-e46f3c0052f1	5d32a5dd-f712-4450-9014-0f9637f596be	Кое-что задаром	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/koe-chto_zadarom/koe-chto_zadarom.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/koe-chto_zadarom/koe-chto_zadarom.jpg		Джо Коллинзу повезло. Он стал счастливым обладателем Утилизатора класса А, проще говоря — исполнителя желаний. Теперь у него будет ВСЁ, что он пожелает! Вот только не подозревал бедный Джо, что за ВСЁ надо платить...	\N	2025-04-10 17:40:08.917239+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/koe-chto_zadarom/koe-chto_zadarom_mini.jpg	1970-01-01 00:00:00+00	
591d1eff-db77-444a-aaa7-f16c622bcbfc	6928c53a-e978-4bca-9287-e46f3c0052f1	5d32a5dd-f712-4450-9014-0f9637f596be	Ложный диагноз	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/lojniy_diagnoz/lojniy_diagnoz.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/lojniy_diagnoz/lojniy_diagnoz.jpg		Эдвуд Кэсвел, по настоящему больной человек, страдает манией убийства. Купив в магазине Рекс-Регенератор, он надеется вылечиться от опасной болезни. Откуда же ему знать, что это демонстрационная модель и предназначена она для марсиан.	\N	2025-04-10 17:49:30.988268+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/lojniy_diagnoz/lojniy_diagnoz_mini.jpg	1970-01-01 00:00:00+00	
71eb3f52-3506-420b-baf4-8ee2b41d657f	6928c53a-e978-4bca-9287-e46f3c0052f1	9a936b79-0178-4836-bb05-309fda45a125	Воттоваарские озера	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/vottovaarskie_ozera/vottovaarskie_ozera.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/vottovaarskie_ozera/vottovaarskie_ozera.jpg		А маршрут манил нас с того дня, как Серый вычитал про этих Красных Шаманов. Манил, как солнечный зайчик котёнка. Дрожит, светится, ускользает. Упоминались эти шаманы мимоходом, буквально парой строчек, в аналитике записей древних саами. Дескать, и каменные лабиринты и валуны «на ножках» в Воттовааре создавали саамские Красные Шаманы, которые оживляли камни и заставляли их плясать в «танцах диких и священных». Влад тогда восхитился находке, до того он любил всё, что связано с нежитью и вообще играми со смертью.	\N	2025-04-01 11:14:42.060905+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/vottovaarskie_ozera/vottovaarskie_ozera_mini.jpg	1970-01-01 00:00:00+00	
322b574a-4656-43f8-b60f-96af7fc413aa	6928c53a-e978-4bca-9287-e46f3c0052f1	9a936b79-0178-4836-bb05-309fda45a125	Прошлый мир	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/proshliy_mir/proshliy_mir.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/proshliy_mir/proshliy_mir.jpg	https://www.litres.ru/book/tanya-gurevich-27626786/proshlyy-mir-64055222/	Мир, в котором худшее наказание – новые вещи. Мир, в котором лучший подарок – твоя старая подушка. Это и есть твой Настоящий мир. Всё остальное теперь в Прошлом. Ларри придётся рисковать своей жизнью, возвращаясь на Землю. Но одна из этих вылазок преподнесёт неожиданный сюрприз: дневник, спрятанный в тайнике. Поможет ли это ему разгадать причину бегства людей из Прошлого?	2025-04-11 08:13:46.726272+00	2025-04-11 11:54:32.500117+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/proshliy_mir/proshliy_mir_mini.jpg	1970-01-01 00:00:00+00	
3b11dce7-3e1c-4fed-9212-dca2a0401b52	0d070aaf-5daa-4e7b-b19b-e69be81a408b	7f0da457-8291-4d9d-8d31-7153c7a4e71b	Гараж	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/garazh/garazh.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/garazh/garazh_sqare.jpg	https://www.kinopoisk.ru/film/44467/	На заседании гаражного кооператива предстоит выбрать четырех «крайних», которые должны сами отказаться от будущего собственного гаража. Но выбора, в общем-то, и нет — правление кооператива уже составило список сокращаемых, который собранию надо лишь утвердить.	2025-04-02 10:30:45.870965+00	2025-04-08 12:43:19.230042+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/garazh/garazh_preview.jpg	1970-01-01 00:00:00+00	
e740f417-7352-4f8d-9daf-a51d6aa98994	6928c53a-e978-4bca-9287-e46f3c0052f1	af4dd970-3234-4581-8300-9175bc999ecc	Ведьмак. Перекресток воронов	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/witcher/witcher.m4b	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/witcher/witcher.jpg		На этот раз мэтр польского фэнтези обращается к юности Геральта, когда тот лишь начинал свой путь ведьмака и сталкивался со множеством испытаний. С двумя руническими мечами за спиной он охотится на чудовищ, спасает невинных девушек и приходит на помощь несчастным влюблённым. Везде и всюду он пытается следовать неписаному кодексу, усвоенному от своих учителей и наставников. Но, как это часто бывает, жизнь щедра на разочарования ― юношеский идеализм то и дело разбивается о суровую действительность. Сага продолжается. Ведь история не знает конца…	\N	2025-07-18 13:11:39.506473+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/witcher/witcher_preview.jpg	1970-01-01 00:00:00+00	
4c791340-3aac-4c2a-9120-3a1f507e3967	db20046c-89d6-4484-861e-66619dc45f66	12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подкаст - Выпуск 3	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%913%20%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA%203.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13.jpg			2025-05-12 17:51:11.311142+00	2025-09-22 15:11:06.506072+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png	1970-01-01 00:00:00+00	
5b65afbb-aa11-4657-93bd-dbcc305b8d2c	db20046c-89d6-4484-861e-66619dc45f66	12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подкаст - Выпуск 4	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%913%20%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA%204.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13.jpg			2025-07-15 21:01:02.598913+00	2025-09-22 15:11:16.646773+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png	1970-01-01 00:00:00+00	
aa3e9103-9ace-413b-a274-838ce2c83951	db20046c-89d6-4484-861e-66619dc45f66	12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подкаст - Выпуск 5	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%913%20%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA%205.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13.jpg			2025-07-16 19:59:04.944147+00	2025-09-22 15:11:25.22019+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png	1970-01-01 00:00:00+00	
cf3207c6-220a-490e-9401-ca3cf757b3d7	0d070aaf-5daa-4e7b-b19b-e69be81a408b	7f0da457-8291-4d9d-8d31-7153c7a4e71b	Любовь и голуби	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/lyubovigolubi/%D0%9B%D1%8E%D0%B1%D0%BE%D0%B2%D1%8C%20%D0%B8%20%D0%93%D0%BE%D0%BB%D1%83%D0%B1%D0%B8.MP3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/lyubovigolubi/lyubovigolubi.jpg	https://www.kinopoisk.ru/film/45146/	Василий Кузякин получил путевку на юг. Там он встретил роковую женщину Раису Захаровну и… вернулся Вася с курорта не к себе в деревню, а в дом Раисы Захаровны. Началась для него новая жизнь, в которой было много непонятного и интересного, но не было дома, где остались Надя, дети и голуби.	2025-07-16 11:28:57.864259+00	2025-07-16 11:28:57.864259+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/plays/lyubovigolubi/lyubovigolubi_preview.png	1970-01-01 00:00:00+00	
a99e1d1c-ab95-4e6c-94f9-2c50a2a830a5	6928c53a-e978-4bca-9287-e46f3c0052f1	10e3ecfd-6ede-449c-a764-468c1b02052d	Раскаявшаяся судьба	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/shnitkova/%D0%A0%D0%B0%D1%81%D1%81%D0%BA%D0%B0%D1%8F%D0%B2%D1%88%D0%B0%D1%8F%D1%81%D1%8F_%D1%81%D1%83%D0%B4%D1%8C%D0%B1%D0%B0.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/shnitkova/%D0%A0%D0%B0%D1%81%D1%81%D0%BA%D0%B0%D1%8F%D0%B2%D1%88%D0%B0%D1%8F%D1%81%D1%8F_%D1%81%D1%83%D0%B4%D1%8C%D0%B1%D0%B0.jpg		Тема этой новеллы – автобиографическая и даже, если можно так сказать, автотворческая: писательница Тэффи нашла своеобразный повод порассуждать о том, как воспринимают её творчество читатели и зрители и какова она сама, если её творчество именно таково, каково оно есть.  Сюжетом новеллы является течение всего одной, да и то, как это поначалу кажется (да и к концу оказывается!), довольно глупой беседы.	2025-07-22 12:16:24.196061+00	2025-07-23 11:00:31.502633+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/shnitkova/%D0%A0%D0%B0%D1%81%D1%81%D0%BA%D0%B0%D1%8F%D0%B2%D1%88%D0%B0%D1%8F%D1%81%D1%8F_%D1%81%D1%83%D0%B4%D1%8C%D0%B1%D0%B0_mini.jpg	1970-01-01 00:00:00+00	
b8c6a867-0604-46f9-98cf-d4c6d746af5b	db20046c-89d6-4484-861e-66619dc45f66	12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подкаст - Выпуск 1	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%913%20%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA%201.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13.jpg			2025-04-17 13:49:31.618582+00	2025-09-22 15:10:41.031951+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png	1970-01-01 00:00:00+00	
330c428b-dcea-403c-848e-b1809fc0547f	db20046c-89d6-4484-861e-66619dc45f66	12bf57e6-b7bf-4648-9a50-8e1f463d8c20	Неидеальный подкаст - Выпуск 2	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%913%20%D0%92%D1%8B%D0%BF%D1%83%D1%81%D0%BA%202.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13.jpg			2025-04-17 14:23:33.061327+00	2025-09-22 15:10:52.480169+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png	1970-01-01 00:00:00+00	
d9aed84f-cfdb-41d7-aeb0-e4a4b14e0732	6928c53a-e978-4bca-9287-e46f3c0052f1	56ef83ad-6d2f-422b-a8c6-726a163d4913	Вебер	0	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/veber/%D0%92%D0%B5%D0%B1%D0%B5%D1%80.mp3	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/veber/ivlanda_veber.jpg	https://author.today/work/531495	Адвокат Теодор Рихтер приходит в полицию с ужасающим признанием: его лучший друг и коллега Эшер Райхерт – хладнокровный убийца. Но то, что казалось исповедью душегуба, оказывается началом игры... Смертельной игры.  Холодная война, объявленная в мирное время, не заканчивается хорошо. Никогда.	2026-01-03 19:25:06.541813+00	2026-01-03 19:25:06.541813+00	\N	https://bookreader.hb.ru-msk.vkcloud-storage.ru/audiobooks/veber/ivlanda_veber_mini.jpg	1970-01-01 00:00:00+00	
\.


--
-- Data for Name: sections; Type: TABLE DATA; Schema: public; Owner: vapor_username
--

COPY public.sections (id, section_id, name, title, cover_url, text_link, description, template, book_template) FROM stdin;
6928c53a-e978-4bca-9287-e46f3c0052f1	\N	audiobooks	Аудиокниги					
0d070aaf-5daa-4e7b-b19b-e69be81a408b	\N	plays	Спектакли			Аудиоспектакли		
b8a7e85f-8a55-4a67-97f8-d4b6ecfc995a	\N	podcasts	Подкасты					
29c2266d-47b3-4047-8182-2dae1592973f	b8a7e85f-8a55-4a67-97f8-d4b6ecfc995a	psy	Психология					
db20046c-89d6-4484-861e-66619dc45f66	29c2266d-47b3-4047-8182-2dae1592973f	b-three	Неидеальный подкаст	https://bookreader.hb.ru-msk.vkcloud-storage.ru/podcasts/psy/b-three/%D0%B13_preview.png				
\.


--
-- Name: _fluent_migrations _fluent_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public._fluent_migrations
    ADD CONSTRAINT _fluent_migrations_pkey PRIMARY KEY (id);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: _fluent_migrations uq:_fluent_migrations.name; Type: CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public._fluent_migrations
    ADD CONSTRAINT "uq:_fluent_migrations.name" UNIQUE (name);


--
-- Name: books books_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(id);


--
-- Name: books books_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- Name: sections sections_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: vapor_username
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.sections(id);


--
-- PostgreSQL database dump complete
--

\unrestrict qcpl3mQjCf6UJVhazUkM9Sxw9Kxa7B9GNFiatrghErSdUrDN3FzBuMxJGQtZcGj

