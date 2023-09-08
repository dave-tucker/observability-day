# Using eBPF to Retrofit ⏮️ and Extend ⏭️ Observability

---

## whoami

- 👋 Hi, I'm Dave Tucker
- 👷 Principal Sw Eng. OCTO Networking
- 🤓 Networking, Linux Container and eBPF nerd

---

## ⚠️ Disclaimer ⚠️

- This is forward looking technology
- Not all features have been implemented
- Expected timeframe to completion: 2023Q4

---

## Retrofit

**retrofit** *(verb)*

/ˈrɛtrə(ʊ)ˌfɪt/

add (a component or accessory) to something that did not have it when manufactured.

----

## Why?

Observability is awesome if you have the ability to instrument
your applications...

But what if you want to observe a legacy app that you brought into OpenShift?

----

## Triangle Corps 🔺

Triangle Corps was establised in the early 1970s as the premium provider of
equilateral triangle area calculations.

They used to run an IBM Mainframe but decided to migrate their stack over to
OpenShift.

----

## The Legacy App

FORTRAN 🎉

```fortran
PROGRAM Triangle
    IMPLICIT NONE
    REAL :: a, b, c, Area
    CALL RANDOM_INIT(.true., .true.)
    DO
      CALL RANDOM_NUMBER(a)
      a = FLOAT(INT(a * 1000))
      b = a
      c = a
      PRINT *, 'Computing Area of Triangles'
      PRINT *, 'Values: ', a, b, c
      PRINT *, 'Area: ', Area(a, b, c)
      CALL SLEEP(1)
    END DO
    PRINT *, 'Done'
END PROGRAM Triangle

FUNCTION Area(x,y,z)
    IMPLICIT NONE
    REAL :: Area            ! function type
    REAL, INTENT( IN ) :: x, y, z
    REAL :: theta, height
    theta = ACOS((x**2+y**2-z**2)/(2.0*x*y))
    height = x*SIN(theta); Area = 0.5*y*height
END FUNCTION Area
```

----

## The problem

The customer wants to monitor the usage of their area service, but:

- There are OpenTelemetry of Prometheus bindings for FORTRAN
- The employee who wrote this has retired
- They're working on a V2 service, but need the monitoring in place now.

----

## The solution

Knowing a little bit about the layout of the program...

```console
0x00000112:   DW_TAG_subprogram
                DW_AT_external  (true)
                DW_AT_name      ("area")
                DW_AT_decl_file ("/home/dave/dev/observability-day/fortran/test.f90")
                DW_AT_decl_line (22)
                DW_AT_linkage_name      ("area_")
                DW_AT_type      (0x0000010b "real(kind=4)")
                DW_AT_low_pc    (0x00000000004011d6)
                DW_AT_high_pc   (0x00000000004012a0)
                DW_AT_frame_base        (DW_OP_call_frame_cfa)
                DW_AT_call_all_tail_calls       (true)
```

----

## eBPF

We can write an eBPF probe that increments a counter each time that function is
hit. Or perhaps ChatGPT (or other LLM) can write it for us 😏

```c
#include <linux/types.h>
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

struct {
	__uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
	__type(key, __u32);
	__type(value, long);
	__uint(max_entries, 1);
} counter_area SEC(".maps");

SEC("uprobe/test:area_")
int area_counter(struct pt_regs *ctx)
{
 	long * count;
    count = bpf_map_lookup_elem(&counter_area, 0);
	if (count)
		count += 1;
	return 0;
}
```

----

## And deploy it on OpenShift

With a little help from bpfd - our OpenShift eBPF operator.

```console
kubectl apply -f observe-fortran.yaml
```

```yaml
apiVersion: bpfd.io/v1alpha1
kind: UprobeProgram
metadata:
  labels:
    app.kubernetes.io/name: uprobeprogram
  name: observe-fortran
spec:
  name: area_counter
  metrics:
    area:
      map_type: PerCpuArray
      map_name: area_counter
      metric_type: counter
      name: triangle_corp_area_total
      description: Total number of times area has been called
  nodeselector: {}
  namespaceselector:
    matchLabels:
      project: area
  podselector:
    matchLabels:
      component: area
  containerselector:
    matchLabels:
      name: area
  process: /test
```

----

## Result

Metrics are available in OTEL/Prometheus format:

```console
# HELP triangle_corp_area_total Total number of times area has been called
# TYPE triangle_corp_area_total counter
triangle_corp_area_total 51
```

----

## Outcome

Triangle Corps 🔺 are able to measure the total number of requests/second handled
by their legacy application.

This not only helps them monitor their legacy service, but they are also able
to test their V2 service to ensure they are matching or exceeding performance
expections.

---

## Extend

**extend** *(verb)*

/ɪkˈstend/

[transitive] to make a business, an idea, an influence, etc. cover more areas or operate in more places

----

## Why?

Kernel metrics can be key to indentifying the root cause of performance issues.

----

## Triangle Corps 🔺

- Area App v2 has been released 🎊
- Customer demand for Area App v2 has increased, so they added some horizontal scaling
- From their metrics they can see spikes in request latency, but CPU usage seems steady
- They would like to know if this is an application, or a platform issue

----

## Writing an eBPF Probe

We can adapt [runqslower](https://github.com/iovisor/bcc/blob/master/libbpf-tools/runqslower.bpf.c).

Instead of producing a stream of events, we'll produce a summary.

----

## Deploying on OpenShift

And with some more help from bpfd... we can deploy on OpenShift.

```console
kubectl apply -f runqslower.yaml
```

```yaml
apiVersion: bpfd.io/v1alpha1
kind: KprobeProgram
metadata:
  labels:
    app.kubernetes.io/name: kprobeprogram
  name: runqslower
spec:
  name: runqslower
  metrics:
    area:
      map_type: PerCpuArray
      map_name: runqslower
      metric_type: summary
      name: triangle_corp_runq_microseconds
      description: A summary of time spent waiting for CPU (microseconds)
  nodeselector: {}
  namespaceselector:
    matchLabels:
      project: area
  podselector:
    matchLabels:
      component: area
  containerselector:
    matchLabels:
      name: area
  process: /test
```

----

## Result

Metrics are available in OTEL/Prometheus format:

```console
# HELP triangle_corp_runq_microseconds A summary of time spent waiting for CPU (microseconds)
# TYPE triangle_corp_runq_microseconds summary
triangle_corp_runq_microseconds{quantile="0"} 0
triangle_corp_runq_microseconds{quantile="0.25"} 0
triangle_corp_runq_microseconds{quantile="0.5"} 0
triangle_corp_runq_microseconds{quantile="1"} 0
triangle_corp_runq_microseconds_sum 0
triangle_corp_runq_microseconds_count
```

----

## Outcome

Triangle Corps 🔺 notice a correlation between time spent waiting for CPU and 
their request latency. Area App V2 is fine, but it turns out that replicas of
Area App V2 are competing for CPU time. Adding more worker nodes and adding
some topology-spread constraints to pods.

---

## Conclusion

eBPF is NOT Just for Customers

We'd like to make the eBPF operator part of the base OpenShift distribution,
so you can use it too!

- Provides a K8s native way to manage eBPF.
- Enhanced Security and Auditability of eBPF usage.
- Exports its own metrics about eBPF usage on the cluster, which could be useful to us, and customers.
