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
