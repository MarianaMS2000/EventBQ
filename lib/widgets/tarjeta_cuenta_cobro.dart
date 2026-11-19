import 'package:flutter/material.dart';
import '../repositories/usuario_repository.dart';
import '../theme/colores.dart';
import 'aviso_exito.dart';

/// Tarjeta reutilizable para que los organizadores configuren y visualicen
/// su cuenta de recaudo (Nequi, Daviplata, Bancolombia, etc.)
class TarjetaCuentaCobro extends StatelessWidget {
  final VoidCallback? onActualizado;

  const TarjetaCuentaCobro({super.key, this.onActualizado});

  @override
  Widget build(BuildContext context) {
    final u = UsuarioRepository().obtenerUsuarioActual();
    final tieneCuenta =
        u.cuentaCobroNumero != null && u.cuentaCobroNumero!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tieneCuenta
              ? const Color(0xFF43A047).withValues(alpha: 0.4)
              : const Color(0xFFD5D8E0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tieneCuenta
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFF5E6FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        tieneCuenta
                            ? Icons.account_balance_wallet_rounded
                            : Icons.add_card_rounded,
                        color: tieneCuenta
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF6C2D82),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cuenta para recibir pagos',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colores.azulOscuro,
                            ),
                          ),
                          if (tieneCuenta)
                            const Text(
                              '✓ Cuenta vinculada para recaudos',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _abrirDialogoConfiguracion(context, u),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tieneCuenta
                      ? const Color(0xFFF0F4F8)
                      : Colores.azulOscuro,
                  foregroundColor: tieneCuenta
                      ? Colores.azulOscuro
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: tieneCuenta
                          ? const Color(0xFFCAD4E0)
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Text(
                  tieneCuenta ? 'Editar' : 'Configurar',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tieneCuenta) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E7EE)),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconoPorTipo(u.cuentaCobroTipo),
                    size: 18,
                    color: Colores.azulOscuro,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${u.cuentaCobroTipo ?? "Nequi"}: ${u.cuentaCobroNumero} · Titular: ${u.cuentaCobroTitular ?? u.nombre}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colores.azulOscuro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Las ganancias de las ventas de tickets de tus eventos pagos se registrarán a esta cuenta.',
              style: TextStyle(
                fontSize: 11,
                color: Colores.grisTexto,
                height: 1.3,
              ),
            ),
          ] else ...[
            const Text(
              'Vincula tu Nequi, Daviplata o cuenta bancaria para que los ingresos de tus eventos pagos se depositen a tu nombre.',
              style: TextStyle(
                fontSize: 12,
                color: Colores.grisTexto,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconoPorTipo(String? tipo) {
    final t = (tipo ?? '').toLowerCase();
    if (t.contains('banco') || t.contains('ahorros')) {
      return Icons.account_balance_rounded;
    }
    return Icons.phone_android_rounded;
  }

  Future<void> _abrirDialogoConfiguracion(BuildContext context, dynamic u) async {
    String tipoSeleccionado = u.cuentaCobroTipo ?? 'Nequi';
    final numeroCtrl = TextEditingController(text: u.cuentaCobroNumero ?? '');
    final titularCtrl =
        TextEditingController(text: u.cuentaCobroTitular ?? u.nombre);

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colores.fondo,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.payments_rounded, color: Colores.azulOscuro),
              SizedBox(width: 10),
              Text(
                'Cuenta de Recaudo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colores.azulOscuro,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elige dónde deseas recibir los pagos de los asistentes a tus eventos:',
                  style: TextStyle(fontSize: 12, color: Colores.grisTexto),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tipo de Billetera o Banco:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD5D8E0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: tipoSeleccionado,
                      isExpanded: true,
                      items: [
                        'Nequi',
                        'Daviplata',
                        'Bancolombia (Ahorros)',
                        'Movii',
                        'Dale!',
                      ]
                          .map((m) =>
                              DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setStateDialog(() => tipoSeleccionado = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Número de Celular o Cuenta:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: numeroCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Ej: 3001234567 o # de cuenta',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nombre del Titular:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colores.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: titularCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nombre de la persona o marca',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFFF57F17)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Nota académica: En esta versión del proyecto, los datos se guardan de forma segura en Firebase para simular los recaudos del organizador.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5D4037),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colores.grisTexto)),
            ),
            ElevatedButton(
              onPressed: () {
                if (numeroCtrl.text.trim().length >= 6) {
                  Navigator.pop(ctx, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colores.azulOscuro,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (guardado == true && context.mounted) {
      await UsuarioRepository().actualizarDatosCobro(
        tipo: tipoSeleccionado,
        numero: numeroCtrl.text.trim(),
        titular: titularCtrl.text.trim(),
      );
      if (context.mounted) {
        mostrarAvisoExito(context, '¡Cuenta para recibir pagos guardada!');
        onActualizado?.call();
      }
    }
  }
}
