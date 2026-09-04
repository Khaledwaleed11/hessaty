import 'package:flutter/material.dart';

import '../models/level_model.dart';
import '../services/level_service.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  List<LevelModel> _levels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  // ============================================================
  // LOAD LEVELS
  // ============================================================

  Future<void> _loadLevels() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final levels = await LevelService.getLevels();

      levels.sort(
            (a, b) => a.name.compareTo(b.name),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _levels = levels;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'حدث خطأ أثناء تحميل المستويات.',
        isError: true,
      );
    }
  }

  // ============================================================
  // ADD / EDIT LEVEL
  // ============================================================

  Future<void> _showLevelDialog({
    LevelModel? level,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _LevelDialog(
          level: level,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      await _loadLevels();

      if (!mounted) {
        return;
      }

      _showMessage(
        level == null
            ? 'تم إضافة المستوى بنجاح.'
            : 'تم تعديل المستوى بنجاح.',
      );
    }
  }

  // ============================================================
  // DELETE LEVEL
  // ============================================================

  Future<void> _deleteLevel(
      LevelModel level,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors =
            Theme.of(context).colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          icon: Icon(
            Icons.warning_amber_rounded,
            color: colors.error,
            size: 42,
          ),

          title: const Text(
            'حذف المستوى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            'هل أنت متأكد من حذف مستوى "${level.name}"؟\n\n'
                'لن يتم حذف الطلاب أو الحصص المرتبطة به، '
                'لكن يجب التأكد من عدم استخدامه قبل الحذف.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.6,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('إلغاء'),
            ),

            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                colors.error,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await LevelService.removeLevel(
        level.id,
      );

      await _loadLevels();

      if (!mounted) {
        return;
      }

      _showMessage(
        'تم حذف المستوى بنجاح.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'حدث خطأ أثناء حذف المستوى.',
        isError: true,
      );
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
          TextDirection.rtl,
        ),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        isError ? Colors.red : null,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        colors.surfaceContainerLowest,

        // ======================================================
        // APP BAR
        // ======================================================

        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor:
          colors.surfaceContainerLowest,
          surfaceTintColor:
          Colors.transparent,

          title: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const Text(
                'المستويات والمصاريف',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'إدارة المستويات والمصاريف الشهرية',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  FontWeight.w600,
                  color: colors
                      .onSurfaceVariant,
                ),
              ),
            ],
          ),

          centerTitle: false,

          actions: [
            Padding(
              padding:
              const EdgeInsets.only(
                left: 12,
              ),
              child: Material(
                color: colors.surface,
                borderRadius:
                BorderRadius.circular(13),
                child: InkWell(
                  borderRadius:
                  BorderRadius.circular(13),
                  onTap: _loadLevels,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 21,
                      color:
                      colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // ======================================================
        // FAB
        // ======================================================

        floatingActionButton:
        FloatingActionButton.extended(
          onPressed: () {
            _showLevelDialog();
          },
          icon: const Icon(
            Icons.add_rounded,
          ),
          label: const Text(
            'إضافة مستوى',
            style: TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),

        // ======================================================
        // BODY
        // ======================================================

        body: RefreshIndicator(
          color: colors.primary,
          backgroundColor:
          colors.surface,
          onRefresh: _loadLevels,
          child: _buildBody(colors),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
      ColorScheme colors,
      ) {
    if (_isLoading) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 300),
          Center(
            child:
            CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_levels.isEmpty) {
      return _buildEmptyState(colors);
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        100,
      ),
      children: [
        _buildHeaderCard(colors),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: Text(
                'المستويات',
                textAlign:
                TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w900,
                  color:
                  colors.onSurface,
                ),
              ),
            ),
            Text(
              '${_levels.length} مستوى',
              style: TextStyle(
                fontSize: 9,
                fontWeight:
                FontWeight.w700,
                color:
                colors.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ..._levels.map(
              (level) => Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),
            child:
            _buildLevelCard(
              level,
              colors,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
      ColorScheme colors,
      ) {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding:
      const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        100,
      ),
      children: [
        const SizedBox(height: 20),

        _buildHeaderCard(colors),

        const SizedBox(height: 24),

        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 35,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: colors
                  .outlineVariant
                  .withValues(
                alpha: 0.25,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 75,
                height: 75,
                decoration:
                BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.layers_outlined,
                  size: 35,
                  color:
                  colors.primary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'لا توجد مستويات حتى الآن',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w900,
                  color:
                  colors.onSurface,
                ),
              ),

              const SizedBox(height: 7),

              Text(
                'أضف المستويات الدراسية وحدد المصاريف الشهرية لكل مستوى.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.6,
                  color: colors
                      .onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: () {
                  _showLevelDialog();
                },
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text(
                  'إضافة أول مستوى',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard(
      ColorScheme colors,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:
          Alignment.topRight,
          end:
          Alignment.bottomLeft,
          colors: [
            colors.primary,
            Color.lerp(
              colors.primary,
              colors.primaryContainer,
              0.52,
            )!,
          ],
        ),
        borderRadius:
        BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.primary
                .withValues(
              alpha: 0.18,
            ),
            blurRadius: 26,
            offset:
            const Offset(0, 11),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.14,
              ),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons.layers_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                const Text(
                  'إدارة المستويات',
                  style: TextStyle(
                    color:
                    Colors.white,
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'حدد المصاريف الشهرية لكل مستوى',
                  style: TextStyle(
                    color: Colors.white
                        .withValues(
                      alpha: 0.76,
                    ),
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: Text(
              '${_levels.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEVEL CARD
  // ============================================================

  Widget _buildLevelCard(
      LevelModel level,
      ColorScheme colors,
      ) {
    return Material(
      color: colors.surface,
      borderRadius:
      BorderRadius.circular(22),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(22),
        onTap: () {
          _showLevelDialog(
            level: level,
          );
        },
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: colors
                  .outlineVariant
                  .withValues(
                alpha: 0.30,
              ),
            ),
          ),
          child: Row(
            children: [
              // ================================================
              // Icon
              // ================================================

              Container(
                width: 50,
                height: 50,
                decoration:
                BoxDecoration(
                  color: colors.primary
                      .withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color:
                  colors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 13),

              // ================================================
              // Name + Fee
              // ================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      level.name,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons
                              .payments_rounded,
                          size: 16,
                          color:
                          colors.primary,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${level.monthlyFee.toStringAsFixed(0)} جنيه / شهر',
                          style:
                          TextStyle(
                            fontSize: 10,
                            fontWeight:
                            FontWeight.w700,
                            color: colors
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ================================================
              // Menu
              // ================================================

              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors
                      .onSurfaceVariant,
                ),
                onSelected:
                    (value) {
                  if (value ==
                      'edit') {
                    _showLevelDialog(
                      level: level,
                    );
                  }

                  if (value ==
                      'delete') {
                    _deleteLevel(
                      level,
                    );
                  }
                },
                itemBuilder:
                    (context) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'تعديل',
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'حذف',
                          ),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// LEVEL DIALOG
// ==================================================================

class _LevelDialog extends StatefulWidget {
  final LevelModel? level;

  const _LevelDialog({
    this.level,
  });

  @override
  State<_LevelDialog> createState() =>
      _LevelDialogState();
}

class _LevelDialogState
    extends State<_LevelDialog> {
  final _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _feeController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text: widget.level?.name ?? '',
        );

    _feeController =
        TextEditingController(
          text: widget.level == null
              ? ''
              : widget.level!.monthlyFee
              .toStringAsFixed(0),
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final name =
    _nameController.text.trim();

    final fee = double.tryParse(
      _feeController.text.trim(),
    );

    if (fee == null || fee < 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final level = LevelModel(
        id: widget.level?.id ??
            DateTime.now()
                .microsecondsSinceEpoch
                .toString(),
        name: name,
        monthlyFee: fee,
      );

      if (widget.level == null) {
        await LevelService.addLevel(
          level,
        );
      } else {
        await LevelService.updateLevel(
          level,
        );
      }

      if (!mounted) {
        return;
      }

      // مهم جدًا:
      // نقفل الـ Dialog فقط بعد انتهاء عملية الحفظ.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'حدث خطأ أثناء حفظ المستوى.',
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD DIALOG
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final colors =
        Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor:
      colors.surface,
      surfaceTintColor:
      Colors.transparent,

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(28),
      ),

      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color: colors.primary
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                13,
              ),
            ),
            child: Icon(
              widget.level == null
                  ? Icons.add_rounded
                  : Icons.edit_rounded,
              color:
              colors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              widget.level == null
                  ? 'إضافة مستوى جديد'
                  : 'تعديل المستوى',
              style:
              const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.w900,
              ),
            ),
          ),
        ],
      ),

      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            // ==================================================
            // Name
            // ==================================================

            TextFormField(
              controller:
              _nameController,
              enabled: !_isSaving,
              textDirection:
              TextDirection.rtl,
              textAlign:
              TextAlign.right,
              textInputAction:
              TextInputAction.next,
              decoration:
              InputDecoration(
                labelText:
                'اسم المستوى',
                hintText:
                'مثال: المستوى الأول',
                prefixIcon:
                const Icon(
                  Icons
                      .school_outlined,
                ),
                filled: true,
                fillColor: colors
                    .surfaceContainerLowest,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide(
                    color: colors
                        .outlineVariant
                        .withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide(
                    color:
                    colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'اكتب اسم المستوى';
                }

                if (value
                    .trim()
                    .length <
                    2) {
                  return 'اسم المستوى قصير جدًا';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // Fee
            // ==================================================

            TextFormField(
              controller:
              _feeController,
              enabled: !_isSaving,
              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal: true,
              ),
              textDirection:
              TextDirection.ltr,
              textAlign:
              TextAlign.left,
              textInputAction:
              TextInputAction.done,
              onFieldSubmitted:
                  (_) {
                if (!_isSaving) {
                  _save();
                }
              },
              decoration:
              InputDecoration(
                labelText:
                'المصاريف الشهرية',
                hintText:
                'مثال: 500',
                suffixText:
                'جنيه',
                prefixIcon:
                const Icon(
                  Icons
                      .payments_outlined,
                ),
                filled: true,
                fillColor: colors
                    .surfaceContainerLowest,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide(
                    color: colors
                        .outlineVariant
                        .withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    15,
                  ),
                  borderSide:
                  BorderSide(
                    color:
                    colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value
                        .trim()
                        .isEmpty) {
                  return 'اكتب المصاريف الشهرية';
                }

                final fee =
                double.tryParse(
                  value.trim(),
                );

                if (fee == null) {
                  return 'اكتب رقم صحيح';
                }

                if (fee < 0) {
                  return 'المصاريف لا يمكن أن تكون سالبة';
                }

                return null;
              },
            ),
          ],
        ),
      ),

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.of(context)
                .pop(false);
          },
          child: const Text(
            'إلغاء',
          ),
        ),

        FilledButton(
          onPressed:
          _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
            width: 20,
            height: 20,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              Colors.white,
            ),
          )
              : Text(
            widget.level == null
                ? 'إضافة'
                : 'حفظ التعديل',
          ),
        ),
      ],
    );
  }
}