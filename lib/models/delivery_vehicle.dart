/// How a fuel load reaches (or leaves) the station: the owner's own truck
/// ("Self") or a hired carriage. Shared by purchase orders and the Logs
/// screen's vehicle log, so both use the same two values and labels.
enum DeliveryVehicle {
  self('Self'),
  carriage('Carriage');

  const DeliveryVehicle(this.label);

  /// Display text, e.g. for a badge or a dropdown option.
  final String label;
}
