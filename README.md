# nasc-blog
This is our blog :)

# About Hugo
> Hugo is a general-purpose website framework. Technically speaking, Hugo is a static site generator. Unlike other systems which dynamically build a page every time a visitor requests one, Hugo does the building when you create your content. Since websites areviewed far more often than they are edited, Hugo is optimized for website viewing while providing a great writing experience.

Please check Hugo installing page -> https://gohugo.io/overview/installing/
Hugo is written in [Go](https://gohugo.io/overview/installing/), so you'll first need to install it.

## New post
```
hugo new post/my-first-post.md
```

## Running
First, clone this repo and then.
I'm using the Casper theme, which is a "copy" of Ghost Casper theme (which I was using previously).
If you want to use Casper, just clone it to the `themes` directory.

```
hugo server --theme=hugo-theme-casper-master
```
Navigate to `localhost:1313` and you'll probably see my personal blog locally.
