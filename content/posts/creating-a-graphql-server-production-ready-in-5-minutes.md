---
title: "Creating a GraphQL server, production-ready, in 5 minutes"
date: 2017-12-22T17:17:54-02:00
draft: true
image: "/images/creating-a-graphql-server-production-ready-in-5-minutes.jpg"
author: "Jaydson Gomes"
authorwebsite: "https://jaydson.com"
authorbio: "@BrazilJS co-founder, Nasc co-founder, Software developer (mostly JavaScript), Facebook DevC Lead, BrazilJS author/editor"
authoravatar: "https://pbs.twimg.com/profile_images/651961298398375936/bJiGtvgO_400x400.jpg"
authorlocation: "Porto Alegre, Brazil"
---

You probably already heard about [GraphQL][1], right?  
When I decided to stop to study it, in a couple of hours I came to the following conclusion:  

> GraphQL is one of the smartest things I've ever seen in this little dev world. It's hard to see a technology being so easy and intuitive.  

Link to the original Tweet: [https://twitter.com/jaydson/status/922849780975460352](https://twitter.com/jaydson/status/922849780975460352)  

GraphQL is a query language, as well as the old well-known SQL.  
However, GraphQL focus are APIs.  
With GraphQL the power is in the client, so it is possible to request exactly what is needed in a query, resulting in productivity, autonomy and performance.  
Evolve GraphQL APIs become an easy task, because there's no need to create new routes or end-points.  
Another powerful detail is the possibility 

Another powerful GraphQL detail is the possible emergence of new set of tools for developers.

<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-2017-11-3-GraphQL-A-query-language-for-APIs-2-940x333.png" alt="screenshot-2017-11-3-graphql-a-query-language-for-apis-2" width="940" height="333" class="aligncenter size-large wp-image-3607" />

Não vamos cobrir os detalhes da tecnologia neste post.  
Sendo assim, o ideal é que o leitor já tenha conhecimento prévio de GraphQL.  
Como dito anteriormente, poucas horas de estudo já serão o suficiente.

Neste post, vamos criar um servidor GraphQL do zero e colocá-lo em produção.  
Ah... um detalhe importante: vamos fazer isso em cinco minutos :)

## Requisitos básicos

👉 Conhecimento básico de GraphQL  
👉 Conhecimento básico de SQL e modelagem de banco de dados  
👉 Conhecimento básico do banco de dados open source Postgres  
👉 Conhecimento básico de Node.js  
👉 Conhecimento básico de ferramentas de linha de comando  
👉 Conhecimento básico de serviços Amazon  
👉 Node.js e Postgres instalado

## Minuto um

Vamos criar uma aplicação clássica, um sistema de blog.  
A ideia é que, a partir deste exemplo, você consiga aplicar todos os passos utilizando a modelagem da sua aplicação.  
Para o nosso super blog, vamos precisar de algumas entidades relacionais:

**[user_account]**  
*Esta entidade representa um usuário no blog. Ele pode ser um autor ou leitor*

**[post]**  
*Post é o artigo/texto do blog*

**[comment]**  
Cada post pode conter n comentários

[caption id="attachment_3557" align="aligncenter" width="471"]<img src="https://braziljs.org/wp-content/uploads/2017/11/blog-demo1.jpg" alt="Diagrama ER do nosso exemplo de aplicação" width="471" height="467" class="size-full wp-image-3557" /> Diagrama ER do nosso exemplo de aplicação[/caption]

Utilizaremos o excelente banco de dados [Postgres][2] para armazenar os dados do nosso blog.  
Para o banco de dados, vou usar [Amazon RDS][3], que é uma solução de database as a service, mas você pode utilizar qualquer outra solução.  
Crie um banco de dados de teste e execute o schema abaixo para criar as tabelas mapeadas para o nosso sistema.

<pre><code class="language-sql">CREATE TABLE user_account (
    id serial PRIMARY KEY,
    username VARCHAR (50) UNIQUE NOT NULL,
    password VARCHAR (50) NOT NULL,
    name VARCHAR (50) NOT NULL,
    email VARCHAR (355) UNIQUE NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT now(),
    last_login TIMESTAMP
);

CREATE TABLE post (
    id serial PRIMARY KEY,
    user_id INTEGER NOT NULL,
    title VARCHAR (100) NOT NULL,
    content TEXT NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT user_fkey FOREIGN KEY (user_id)
    REFERENCES user_account (id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE comment (
    id serial PRIMARY KEY,
    post_id integer NOT NULL,
    user_id integer NOT NULL,
    content TEXT NOT NULL,
    created_on TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT user_fkey FOREIGN KEY (user_id)
    REFERENCES user_account (id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION,
    CONSTRAINT post_fkey FOREIGN KEY (post_id)
    REFERENCES post (id) MATCH SIMPLE
    ON UPDATE NO ACTION ON DELETE NO ACTION
);
</code></pre>

Note as relações entre as entidades:  
Cada `post` possui referência ao `user_account`, estabelecendo uma relação de 1 > 1, onde - basicamente - estamos dizendo que um post no blog possui um usuário.  
Cada `comment` possui referência ao `user_account` e ao `post`, estabelecendo uma relação de 1 > N (post > commment) e 1 > 1 (comment > user), em que estamos dizendo que um post no blog pode conter n comentários e que cada comentário veio de um usuário.

## Minuto dois

Agora, entramos na parte mais legal, a modelagem da nossa API GraphQL.  
E digo que é a parte mais legal, pois não vamos precisar fazer a modelagem.  
Mas como assim, Jaydson?  
Isso mesmo! Com um bom banco de dados modelado, conseguimos inferir as entidades e relações com o [PostGraphQL][4].  
O PostGraphQL cria um schema por reflexão em um banco de dados Postgres.  
Isso quer dizer que podemos focar em construir nosso banco de dados da melhor maneira possível e, após isso, ter uma API GraphQL na ponta preparada para a sua aplicação.  
Legal, né? Mas como fazer?

Seguindo a promessa dos cinco minutos, vamos agora instalar e levantar o servidor GraphQL em nosso ambiente.  
Primeiramente, crie uma pasta e inicie um projeto npm.

<pre><code class="language-shell">mkdir super-blog
cd super-blog
npm init
</code></pre>

Agora, instale o PostGraphQL como dependência:

<pre><code class="language-shell">npm install postgraphql --save
</code></pre>

[caption id="attachment_3585" align="aligncenter" width="541"]<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-from-2017-11-03-12-29-35.png" alt="Resultado após instalar o PostGraphQLResultado após instalar o PostGraphQL" width="541" height="159" class="size-full wp-image-3585" /> Resultado após instalar o PostGraphQL[/caption]

O seu package.json deve ficar parecido com este:

<pre><code class="language-json">{
  "name": "super-blog",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "postgraphql": "^3.5.0"
  }
}
</code></pre>

Agora, adicione o comando start aos scripts npm. Esse comando irá iniciar o nosso servidor GraphQL.

<pre><code class="language-json">"scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "postgraphql -c postgres://$PG_USER:$PG_PASS@$PG_HOST:$PG_PORT/$PG_DBNAME"
 }
</code></pre>

Por medida de segurança, não vamos expor os dados de acesso do nosso servidor e nem deixá-los versionados em repositórios (GitHub, Bitbucket).  
O comando `start` receberá por parâmetro as variáveis de conexão.  
Exemplo:

<pre><code class="language-shell">PG_USER=user PG_PASS=pass PG_HOST=host PG_PORT=port PG_DBNAME=db npm start
</code></pre>

## Minuto três

Vamos adicionar alguns dados no nosso banco de dados para poder testar a API GraphQL.

<pre><code class="language-sql">begin;

insert into user_account (id, username, password, name, email) values
  (1, 'johnsmith','1234','John Smith', 'john.smith@email.com'),
  (2, 'sara', '1234', 'Sara Smith', 'sara.smith@email.com'),
  (3, 'budd', '1234','Budd Deey', 'budd.deey@email.com'),
  (4, 'kathryn','1234','Kathryn Ramirez', 'kathryn.ramirez@email.com'),
  (5, 'joe','1234','Joe Tucker', 'joe.tucker@email.com'),
  (6, 'jaydson','1234','Jaydson Gomes', 'jaydson@nasc.io');

insert into post (id, user_id, title, content) values
  (1, 6, 'Meu primeiro post','Loren Ipsun Dolor 1'),
  (2, 6, 'Meu segundo post','Loren Ipsun Dolor 2'),
  (3, 6, 'Meu terceiro post','Loren Ipsun Dolor 3'),
  (4, 6, 'Meu quarto post','Loren Ipsun Dolor 4'),
  (5, 6, 'Meu quinto post','Loren Ipsun Dolor 5');

insert into comment (id, post_id, user_id, content) values
  (1, 1, 1, 'Muito legal esse post'),
  (2, 1, 2, 'Verdade, muito legal!'),
  (3, 1, 3, 'Eu achei mais ou menos'),
  (4, 2, 1, 'Muito bom!'),
  (5, 2, 5, 'Show'),
  (6, 4, 4, 'Interessante o post!');

commit;
</code></pre>

## Minuto quatro

Agora, vamos levantar o nosso servidor GraphQL em produção.  
Como o servidor GraphQL é uma simples aplicação Node.js, vou utilizar o [now][5] para subir o serviço.  
Será necessário criar uma conta no `now` e ter a ferramenta de linha de comando instalada:

<pre><code class="language-shell">npm install -g now
</code></pre>

Agora, vamos colocar a nossa API no ar:

<pre><code class="language-shell">now -e PG_USER="user" -e PG_PASS="pass" -e PG_HOST="sua_url.rds.amazonaws.com" -e PG_PORT="5432" -e PG_DBNAME="superblog"
</code></pre>

O `now` suporta que variáveis de ambiente sejam passadas durante o deploy, de maneira que o nosso script de `start` irá capturar estas variáveis e iniciar o serviço.  
Não esqueça de substituir corretamente as variáveis, de acordo com os seus dados de acesso.

Se tudo deu certo, o *output* será algo parecido com a imagem a seguir:

[caption id="attachment_3663" align="aligncenter" width="626"]<img src="https://braziljs.org/wp-content/uploads/2017/11/deploy-now-2.png" alt="Fazendo deploy do servidor GraphQL no now" width="626" height="414" class="size-full wp-image-3663" /> Fazendo deploy do servidor GraphQL no now[/caption]

## Minuto cinco

Agora, vamos ver se está tudo funcionando mesmo.  
Ao fazer o deploy no `now`, geramos a seguinte URL: <https://super-blog-fgqbrohgrb.now.sh/>  
Nosso servidor está ativo neste endereço e, para testar, vamos usar o GraphiQL, uma ferramenta para fazer queries e também testar sua API GraphQL.  
Com relação ao PostGraphQL, não precisamos fazer mais nada, pois já temos uma rota para conseguir testar nossa API: `/graphiql`.  
Deixei a URL pública, assim vocês podem testar o exemplo que utilizamos neste post: <https://super-blog-fgqbrohgrb.now.sh/graphiql>

[caption id="attachment_3591" align="aligncenter" width="940"]<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-from-2017-11-03-15-03-58-940x454.png" alt="GraphiQL, ferramenta para testar nossa API GraphQL" width="940" height="454" class="size-large wp-image-3591" /> GraphiQL, ferramenta para testar nossa API GraphQL[/caption]

O PostGraphQL fez o mapeamento do nosso banco de dados e deixou a API GraphQL pronta para consumo. Vamos ver alguns exemplos:

### Listando todos os posts

<pre><code class="language-json">{
  allPosts {
    edges {
      node {
        id
        title
      }
    }
  }
}
</code></pre>

[caption id="attachment_3592" align="aligncenter" width="940"]<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-from-2017-11-03-15-07-49-940x530.png" alt="Listando posts com a API GraphQL" width="940" height="530" class="size-large wp-image-3592" /> Listando posts com a API GraphQL[/caption]

### Listando todos posts de um usuário

<pre><code class="language-json">{
  userAccountById(id:6) {
    name
    postsByUserId {
      edges {
        node {
          title
        }
      }
    }
  }
}
</code></pre>

[caption id="attachment_3593" align="aligncenter" width="940"]<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-from-2017-11-03-15-12-58-940x508.png" alt="Listando posts de um usuário" width="940" height="508" class="size-large wp-image-3593" /> Listando posts de um usuário[/caption]

### Listando todos comentários de um post específico de um usuário específico

<pre><code class="language-json">{
  userAccountById(id:6) {
    name
    postsByUserId(condition: {id:1}) {
      edges {
        node {
          title
          content
          commentsByPostId {
            edges {
                    node {
                content
              }
            }
          }
        }
      }
    }
  }
}
</code></pre>

[caption id="attachment_3594" align="aligncenter" width="940"]<img src="https://braziljs.org/wp-content/uploads/2017/11/Screenshot-from-2017-11-03-15-17-24-940x512.png" alt="Todos comentários de um post de um usuário" width="940" height="512" class="size-large wp-image-3594" /> Todos comentários de um post de um usuário[/caption]

## Conclusão

O PostGraphQL se mostrou uma ferramenta muito interessante, pois abstrai o mapeamento entre o banco de dados e a sua API.  
A API GraphQL gerada das relações entre as entidades é muito útil e permite que, rapidamente, seja criada uma aplicação consumindo-a.  
Podem existir casos em que o mapeamento feito pelo PostGraphQL não atenda totalmente às necessidades da sua aplicação. Neste caso, o PostGraphQL possibilita a criação de *[procedures][6]* no Postgres. Estas *procedures* são mapeadas diretamente para a sua API GraphQL, dando um poder enorme para o desenvolvedor.

A abordagem de se criar uma aplicação iniciando pela API (*api first*) já é uma técnica bem conhecida e difundida entre desenvolvedores de software.  
Com GraphQL, isso se torna ainda mais interessante. Poder evoluir a API sem a necessidade de controle de versões é - de fato - um ponto muito positivo.

<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

 [1]: http://graphql.org/
 [2]: https://www.postgresql.org/
 [3]: https://aws.amazon.com/rds/
 [4]: https://github.com/postgraphql/postgraphql
 [5]: https://zeit.co/now
 [6]: https://github.com/postgraphql/postgraphql/blob/master/docs/procedures.md