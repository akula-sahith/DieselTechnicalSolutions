import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DesktopTableColumn {
  final String label;
  final int flex;
  final Alignment alignment;

  const DesktopTableColumn({
    required this.label,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

class DesktopTableRow {
  final List<Widget> cells;
  final VoidCallback? onTap;

  const DesktopTableRow({
    required this.cells,
    this.onTap,
  });
}

class DesktopTableWidget extends StatelessWidget {
  final List<DesktopTableColumn> columns;
  final List<DesktopTableRow> rows;
  final bool isLoading;
  final Widget? emptyState;

  const DesktopTableWidget({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (rows.isEmpty && emptyState != null) {
      return emptyState!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── TABLE HEADER ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  flex: col.flex,
                  child: Align(
                    alignment: col.alignment,
                    child: Text(
                      col.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── TABLE ROWS ──
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final row = rows[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: row.onTap,
                  hoverColor: AppColors.primary.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    child: Row(
                      children: List.generate(row.cells.length, (colIndex) {
                        final flex = colIndex < columns.length ? columns[colIndex].flex : 1;
                        final align = colIndex < columns.length ? columns[colIndex].alignment : Alignment.centerLeft;
                        return Expanded(
                          flex: flex,
                          child: Align(
                            alignment: align,
                            child: row.cells[colIndex],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
