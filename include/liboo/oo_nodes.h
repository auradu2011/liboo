#ifndef OO_NODES_H
#define OO_NODES_H

#include <stdbool.h>
#include <libfirm/firm.h>

enum {
	pn_InstanceOf_M   = pn_Generic_M,
	pn_InstanceOf_res = pn_Generic_other,
	pn_InstanceOf_max
};

ir_node *new_InstanceOf(ir_node *mem, ir_node *objptr, ir_type *classtype);
ir_node *get_InstanceOf_mem(const ir_node *node);
ir_node *get_InstanceOf_objptr(const ir_node *node);
ir_type *get_InstanceOf_type(const ir_node *node);
bool     is_InstanceOf(const ir_node *node);

enum {
	pn_Arraylength_M   = pn_Generic_M,
	pn_Arraylength_res = pn_Generic_other,
	pn_Arraylength_max
};

ir_node *new_Arraylength(ir_node *mem, ir_node* arrayref);
ir_node *get_Arraylength_mem(const ir_node *node);
ir_node *get_Arraylength_arrayref(const ir_node *node);
bool     is_Arraylength(const ir_node *node);

void     oo_nodes_init(void);

#endif
