# List of issues and clarifications to be addressed in the next version of the standard.

During development of the Accellera UVM 2020 Implementation, the UVM Working Group has encountered
the following issues which resulted in the implementation deviating from the 1800.2-2020 standard.

# Issues

1. Section 18.2.3.4 says that an address map may be added to multiple address maps if it is accessible from multiple pysical interfaces.  This map structure was not supported in UVM1.2 and an attempt to add to multiple address maps would result in an error.  Adding such support will require extensive rework and likely API enhancements, which was not in the scope of the 1.0 implementation effort.  This implementation will still produce an error if an address map is added to multiple address maps.

[Mantis 4009](https://accellera.mantishub.io/view.php?id=4009)

2. Section 18.4.3.6 says that if the map argument passed to get_local_map() is null, then the default map of the parent block is returned. The actual behaviour is to return the result of the get_default_map() call.

[Mantis 7091](https://accellera.mantishub.io/view.php?id=7091)

3. Section 13.1.5.1 says that ``apply_config_settings`` shall search all fields that match for the component's scope.  This operation is very expensive, as it implies a regex check against all resources in the database.  The actual behavior is to only check for fields that have been defined in `` `uvm_field_* `` macros.  See the documentation of `` uvm_component::apply_config_settings_mode `` for more information.
