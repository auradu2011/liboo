package firm;

import com.sun.jna.Pointer;

import firm.bindings.binding_oo;
import firm.nodes.Node;
import firm.oo.nodes.Nodes;

/**
 * Object-Orientation helper library API
 */
public final class OO {
	private static boolean initialized;

	public enum InterfaceCallType {
		RUNTIME_LOOKUP,
		SEARCHED_ITABLE,
		INDEXED_ITABLE,
		SEARCHED_ITABLE_M2F
	}

	private OO() {
	}

	/**
	 * initializes OO library. Must be called once before using any other
	 * functions from this class.
	 */
	public static void init() {
		assert initialized == false; /* we may only use 1 OO object at once... */
		binding_oo.oo_init();
		Nodes.init();
		initialized = true;
	}

	/**
	 * deinitializes OO library. This frees some allocated resources
	 */
	public static void deinit() {
		binding_oo.oo_deinit();
		initialized = false;
	}

	/**
	 * Lower Object-Oriented constructs into low-level stuff
	 */
	public static void lowerProgram() {
		binding_oo.oo_lower();
	}

	/**
	 * Sets the call-type for interface methods
	 * @param callType
	 */
	public static void setInterfaceLookup(InterfaceCallType callType) {
		if (callType == InterfaceCallType.RUNTIME_LOOKUP)
			binding_oo.oo_set_interface_call_type(0);
		else if (callType == InterfaceCallType.SEARCHED_ITABLE)
			binding_oo.oo_set_interface_call_type(1);
		else if (callType == InterfaceCallType.INDEXED_ITABLE)
			binding_oo.oo_set_interface_call_type(2);
		else if (callType == InterfaceCallType.SEARCHED_ITABLE_M2F)
			binding_oo.oo_set_interface_call_type(1 | 4);
	}

	/**
	 * lets you configure which methods should be included in the vtable
	 */
	public static void setMethodExcludeFromVTable(Entity entity, boolean includeInVTable) {
		binding_oo.oo_set_method_exclude_from_vtable(entity.ptr, includeInVTable);
	}

	/**
	 * lets you mark a method as abstract
	 */
	public static void setMethodAbstract(Entity entity, boolean isAbstract) {
		binding_oo.oo_set_method_is_abstract(entity.ptr, isAbstract);
	}

	/**
	 * @return true if method is abstract
	 */
	public static boolean isMethodAbstract(Entity entity) {
		return binding_oo.oo_get_method_is_abstract(entity.ptr);
	}

	public static void setMethodIsFinal(Entity entity, boolean isFinal) {
		binding_oo.oo_set_method_is_final(entity.ptr, isFinal);
	}

	public static boolean getMethodIsFinal(Entity entity) {
		return binding_oo.oo_get_method_is_final(entity.ptr);
	}

	public static void setMethodIsInherited(Entity entity, boolean isInherited) {
		binding_oo.oo_set_method_is_inherited(entity.ptr, isInherited);
	}

	/**
	 * @return true if the given field is transient
	 */
	public static boolean getFieldIsTransient(Entity entity) {
		return binding_oo.oo_get_field_is_transient(entity.ptr);
	}

	/**
	 * lets you mark a method as transient
	 */
	public static void setFieldIsTransient(Entity entity, boolean isTransient) {
		binding_oo.oo_set_field_is_transient(entity.ptr, isTransient);
	}

	/**
	 * lets you specify the binding mode of a method
	 */
	public static void setEntityBinding(Entity entity, binding_oo.ddispatch_binding binding) {
		binding_oo.oo_set_entity_binding(entity.ptr, binding.val);
	}

	/**
	 * returns the binding mode of a method
	 */
	public static binding_oo.ddispatch_binding getEntityBinding(Entity entity) {
		int binding = binding_oo.oo_get_entity_binding(entity.ptr);
		return binding_oo.ddispatch_binding.getEnum(binding);
	}

	/**
	 * Lets you specify static binding for a single call.
	 * This overwrites any possibly different binding information in the
	 * method entity referenced by the call.
	 */
	public static void setCallIsStaticallyBound(Node call, boolean isStaticallyBound) {
		binding_oo.oo_set_call_is_statically_bound(call.ptr, isStaticallyBound);
	}

	/**
	 * @return the unique compile time type id for the given class type.
	 */
	public static int getClassUID(ClassType classType) {
		return binding_oo.oo_get_class_uid(classType.ptr);
	}

	/**
	 * Sets the the unique compile time type id for the given class type.
	 */
	public static void setClassUID(ClassType classType, int uid) {
		binding_oo.oo_set_class_uid(classType.ptr, uid);
	}

	/**
	 * @return the previously set vtable entity for the given class type.
	 */
	public static Entity getClassVTableEntity(ClassType classType) {
		Pointer vtable = binding_oo.oo_get_class_vtable_entity(classType.ptr);
		if (vtable == Pointer.NULL)
			return null;
		return new Entity(vtable);
	}

	/**
	 * lets you specify the entity containing classType's vtable.
	 * Use an entity with a primitive pointer type, and set the ld name.
	 */
	public static void setClassVTableEntity(ClassType classType, Entity vtable) {
		binding_oo.oo_set_class_vtable_entity(classType.ptr, vtable.ptr);
	}

	/**
	 * lets you specify the entity that represents the pointer to the vtable in an instance
	 */
	public static void setClassVPtrEntity(ClassType classType, Entity entity) {
		binding_oo.oo_set_class_vptr_entity(classType.ptr, entity.ptr);
	}

	/**
	 * returns VPTr entity of a class
	 */
	public static Entity getClassVPtrEntity(ClassType classType) {
		Pointer res = binding_oo.oo_get_class_vptr_entity(classType.ptr);
		if (res == null)
			return null;
		return new Entity(res);
	}

	/**
	 * lets you specify the entity that represents the run-time type info data.
	 * Use an entity with a primitive pointer type, and set the ld name.
	 */
	public static void setClassRTTIEntity(ClassType classType, Entity entity) {
		binding_oo.oo_set_class_rtti_entity(classType.ptr, entity.ptr);
	}

	/**
	 * lets you specify whether the given classType is representing an interface type
	 */
	public static void setClassIsInterface(ClassType classType, boolean isInterface) {
		binding_oo.oo_set_class_is_interface(classType.ptr, isInterface);
	}

	public static boolean getClassIsInterface(ClassType classType) {
		return binding_oo.oo_get_class_is_interface(classType.ptr);
	}

	public static void setClassIsAbstract(ClassType classType, boolean isAbstract) {
		binding_oo.oo_set_class_is_abstract(classType.ptr, isAbstract);
	}

	public static boolean getClassIsAbstract(ClassType classType) {
		return binding_oo.oo_get_class_is_abstract(classType.ptr);
	}

	public static void setClassIsFinal(ClassType classType, boolean isFinal) {
		binding_oo.oo_set_class_is_final(classType.ptr, isFinal);
	}

	public static boolean getClassIsFinal(ClassType classType) {
		return binding_oo.oo_get_class_is_final(classType.ptr);
	}
}
