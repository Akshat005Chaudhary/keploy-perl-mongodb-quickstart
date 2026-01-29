#!/usr/bin/env perl
use Mojolicious::Lite;
use MongoDB;
use POSIX qw(strftime);
use String::Random;

# MongoDB connection
my $mongo_uri = $ENV{"MONGO_URI"} || "mongodb://localhost:27017";
my $client = MongoDB->connect($mongo_uri);
my $db     = $client->get_database("url_shortener");
my $coll   = $db->get_collection("urls");

# Health check
get "/" => sub {
    my $c = shift;
    $c->render(json => { status => "URL Shortener API Running" });
};

# POST /shorten
post "/shorten" => sub {
    my $c = shift;

    my $data = $c->req->json;

    # Basic validation
    unless ($data && $data->{url}) {
        return $c->render(
            status => 400,
            json   => { error => "Missing 'url' field" }
        );
    }

    my $original_url = $data->{url};

    # Generate short code
    my $rand = String::Random->new;
    my $code = $rand->randpattern("CCCCCC");  # 6-char code

    # Insert into MongoDB
    $coll->insert_one({
        code        => $code,
        originalUrl => $original_url,
        clicks      => 0,
        createdAt   => strftime("%Y-%m-%dT%H:%M:%SZ", gmtime),
    });

    # Respond
    $c->render(json => {
        code     => $code,
        shortUrl => $c->req->url->base . $code
    });
};

# GET /:code  → Redirect to original URL
get "/:code" => sub {
    my $c = shift;

    my $code = $c->param("code");

    # Look up in MongoDB
    my $doc = $coll->find_one({ code => $code });

    unless ($doc) {
        return $c->render(
            status => 404,
            json   => { error => "Short URL code not found" }
        );
    }

    # Increment click count
    $coll->update_one(
        { code => $code },
        { '$inc' => { clicks => 1 } }
    );

    # Redirect
    return $c->redirect_to($doc->{originalUrl});
};

# GET /stats/:code → View analytics
get "/stats/:code" => sub {
    my $c = shift;

    my $code = $c->param("code");

    my $doc = $coll->find_one({ code => $code });

    unless ($doc) {
        return $c->render(
            status => 404,
            json   => { error => "Stats not found for this code" }
        );
    }

    $c->render(json => {
        code        => $doc->{code},
        originalUrl => $doc->{originalUrl},
        clicks      => $doc->{clicks},
        createdAt   => $doc->{createdAt}
    });
};

app->start;
