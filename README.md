# RDF tool for dbNSFP

---

## How to make RDFs of dbNSFP

`# cd /hoge`

`# mkdir data`

`# cd data`

Download data from 
https://sites.google.com/site/jpopgen/dbNSFP

Get the source code of this tool from github.

`# cd /hoge`

`# git clone https://github.com/med2rdf/dbnsfp.git`

`# cd dbnsfp`

Run docker commands.

`# docker build -t dbnsfp .`

For proxy

`#docker build -t dbnsfp --build-arg HTTPS_PROXY=http://hoge:8080 .`

Now, let's make RDFs!

`# docker run -v /hoge/data:/data dbnsfp ruby /work/mkRDFdbNSFP.rb /work/academic.conf /data/dbNSFPxxxa.chrx`

- Replace dbNSFPxxxa.chrx with the name of the downloaded file when you execute this command.

It outputs /hoge/data/dbNSFPxxxa.chrx.ttl .
- You can replace academic.conf for customizing the rdf.

---
## Citation

This schema was drawed by
https://www.kanzaki.com/works/2009/pub/graph-draw

