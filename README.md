# cfstatsd #

cfstatsd is a ColdFusion client for StatsD [https://github.com/etsy/statsd](https://github.com/etsy/statsd)

More info on StatsD:

http://codeascraft.etsy.com/2011/02/15/measure-anything-measure-everything/

Use it as follows:

```cfm
<cfset statsd = CreateObject("component","cfstatsd").init('statsd.example.com', 8125) />

<cfset statsd.increment("testing.cf.increment") />
<cfset statsd.increment("testing.cf.increment-magnitude", 10) />
<cfset statsd.increment("testing.cf.increment-sampled", 1, .2) />
<cfset statsd.incrementMulti(1, 1, "testing.cf.increment-1", "testing.cf.increment-2", "testing.cf.increment-3") />

<cfset statsd.decrement("testing.cf.decrement") />
<cfset statsd.decrement("testing.cf.decrement-magnitude", 10) />
<cfset statsd.decrement("testing.cf.decrement-sampled", 1, .2) />
<cfset statsd.decrementMulti(1, 1, "testing.cf.decrement-1", "testing.cf.decrement-2", "testing.cf.decrement-3") />

<cfset statsd.timing("testing.cf.timing", 1024) />
<cfset statsd.timing("testing.cf.timing-sampled", 1024, .2) />

<cfset statsd.gauge("testing.cf.gauge", 8675) />
```

Cheers!
