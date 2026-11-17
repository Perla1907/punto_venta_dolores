import 'package:punto_venta_dolores/dominio/excepciones.dart';
import 'package:punto_venta_dolores/dominio/producto.dart';

class LineaCarrito {
  final Producto producto;
  int cantidad;

  LineaCarrito(this.producto, this.cantidad);
  int get importeCentavos => producto.precioCentavos * cantidad;
}

class Carrito {
  // IVA en porcentaje entero (16 = 16%).
  final int tasaIva;
  int descuentoPorcentaje;
  final Map<String, LineaCarrito> _lineas = {};

  Carrito({this.tasaIva = 16, this.descuentoPorcentaje = 0});

  List<LineaCarrito> get lineas => _lineas.values.toList();
  bool get estaVacio => _lineas.isEmpty;

  void agregar(Producto p, {int cantidad = 1}) {
    final actual = _lineas[p.codigo]?.cantidad ?? 0;

    if(actual + cantidad > p.existencias) {
      throw ExistenciasInsuficientesException(p.nombre, p.existencias);
    }

    if (_lineas.containsKey(p.codigo)) {
      _lineas[p.codigo]!.cantidad += cantidad;
    } else {
      _lineas[p.codigo] = LineaCarrito(p, cantidad);
    }
  }

  void quitar(String codigo) => _lineas.remove(codigo);
 
  void vaciar() => _lineas.clear();
 
  /// Los precios YA incluyen IVA: se desglosa el impuesto del total.
  int get totalBrutoCentavos  =>
      _lineas.values.fold(0, (s, l) => s + l.importeCentavos);
  
  int get totalCentavos {
    if (descuentoPorcentaje <= 0) return totalBrutoCentavos;
    int descuentoCentavos = (totalBrutoCentavos * descuentoPorcentaje + 50) ~/ 100;
    return totalBrutoCentavos - descuentoCentavos;
  }
 
  int get subtotalCentavos => totalCentavos - ivaCentavos;
 
  /// iva = total * tasa / (100 + tasa), redondeado con enteros.
  int get ivaCentavos =>
      (totalCentavos * tasaIva + (100 + tasaIva) ~/ 2) ~/ (100 + tasaIva);
 
  int cambio(int pagoCentavos) {
    if (estaVacio) throw CarritoVacioException();
    if (pagoCentavos < totalCentavos) {
      throw PagoInsuficienteException(totalCentavos - pagoCentavos);
    }
    return pagoCentavos - totalCentavos;
  }

  void aplicarDescuento(int porcentaje) {
    if (porcentaje < 0 || porcentaje > 100) {
      throw DescuentoInvalidoException(porcentaje);
    }
    descuentoPorcentaje = porcentaje;
  }
}