export 'package:onyxia/presentation/app.dart';

//Colors and Theme
export 'package:onyxia/core/constants/colors.dart';
export 'package:onyxia/core/constants/styles.dart';
export 'package:onyxia/core/constants/admin_config.dart';
export 'package:onyxia/core/constants/icons.dart';
export 'package:onyxia/data/providers/theme_provider.dart';

//screens
export 'package:onyxia/presentation/screens/artifacts/widgets/artifacts_tree_view.dart';
export 'package:onyxia/presentation/screens/artifacts/widgets/artifacts_tree_context_menu.dart';
export 'package:onyxia/presentation/screens/graph_screen.dart';
export 'package:onyxia/presentation/common_widget/narwhal_angry.dart';
export 'package:onyxia/presentation/common_widget/narwhal_switch.dart';
export 'package:onyxia/presentation/screens/home/widgets/sidebar.dart';

export 'package:onyxia/presentation/screens/home/home_screen.dart';

export 'package:onyxia/presentation/screens/invite_screen.dart';

export 'package:onyxia/presentation/screens/projects/projects.dart';

export 'package:onyxia/data/models/artifacts/canvas/expandable_pin.dart';

//common widgets
export 'package:onyxia/presentation/common_widget/hover_builder.dart';
export 'package:onyxia/presentation/common_widget/narwhal_card.dart';
export 'package:onyxia/presentation/common_widget/narwhal_drawer_layout.dart';
export 'package:onyxia/presentation/common_widget/narwhal_right_click_menu.dart';

export 'package:onyxia/presentation/common_widget/narwhal_overlay.dart';
export 'package:onyxia/presentation/common_widget/narwhal_dropdown_select.dart';
export 'package:onyxia/presentation/common_widget/narwhal_tooltip.dart';
export 'package:onyxia/presentation/common_widget/narwhal_toast.dart';
export 'package:onyxia/presentation/common_widget/narwhal_modal_dialog.dart';
export 'package:onyxia/presentation/common_widget/narwhal_filter_select.dart';
export 'package:onyxia/presentation/common_widget/narwhal_checkbox_filter_select.dart';
export 'package:onyxia/presentation/common_widget/narwhal_text_filter_select.dart';
export 'package:onyxia/presentation/common_widget/comments_list.dart';
export 'package:onyxia/presentation/screens/home/widgets/project_settings_button.dart';
export 'package:onyxia/presentation/common_widget/diff_history_list.dart';
export 'package:onyxia/presentation/common_widget/diff_tile.dart';
export 'package:onyxia/presentation/common_widget/user_profile_overlay.dart';
export 'package:onyxia/presentation/common_widget/navigation_url_builder.dart';
export 'package:onyxia/presentation/common_widget/navigation_context_menu.dart';
export 'package:onyxia/presentation/common_widget/drag_select_painter.dart';
export 'package:onyxia/presentation/common_widget/narwhal_data_table.dart';
export 'package:onyxia/presentation/common_widget/narwhal_paint.dart';
export 'package:onyxia/presentation/common_widget/narwhal_text_style.dart';
export 'package:onyxia/presentation/common_widget/narwhal_button.dart';
export 'package:onyxia/presentation/common_widget/narwhal_icon_button.dart';
export 'package:onyxia/presentation/common_widget/narwhal_sub_section_button.dart';
export 'package:onyxia/presentation/common_widget/narwhal_icon.dart';
export 'package:onyxia/presentation/common_widget/narwhal_icon_picker_overlay.dart';
export 'package:onyxia/presentation/common_widget/initials_circle.dart';
export 'package:onyxia/presentation/common_widget/onyxia_button.dart';
export 'package:onyxia/services/item_title_validation_service.dart';

export 'package:onyxia/data/providers/artifacts_diff_preview_provider.dart';
export 'package:onyxia/presentation/screens/artifacts/widgets/editor_link_dialog.dart';
export 'package:onyxia/presentation/screens/artifacts/widgets/editor_context_menu.dart';
export 'package:onyxia/presentation/screens/artifacts/widgets/hover_comment_container.dart';
export 'package:onyxia/presentation/screens/artifacts/widgets/artifact_comment.dart'
    hide CommentMenu, SubCommentMenuAction;
export 'package:onyxia/presentation/screens/artifacts/widgets/tree_tile.dart';

// Editor Views
export 'package:onyxia/presentation/artifact_editor/artifact_editor.dart';
export 'package:onyxia/presentation/artifact_editor/canvas/canvas_editor_view.dart';
export 'package:onyxia/presentation/artifact_editor/pending_action_bar.dart';

export 'package:onyxia/presentation/routing/router.dart';
export 'package:onyxia/presentation/routing/routes.dart';

//data providers
export 'package:onyxia/data/providers/auth_provider.dart';
export 'package:onyxia/data/providers/comments_provider.dart';
export 'package:onyxia/data/providers/projects_provider.dart';
export 'package:onyxia/data/providers/current_user_provider.dart';
export 'package:onyxia/data/providers/user_definitions_provider.dart';
export 'package:onyxia/data/providers/current_user_role_provider.dart';
export 'package:onyxia/data/providers/user_lookup_provider.dart';
export 'package:onyxia/data/providers/user_references_provider.dart';
export 'package:onyxia/data/providers/project_members_provider.dart';
export 'package:onyxia/data/providers/canvases_provider.dart';
export 'package:onyxia/data/providers/artifacts_provider.dart';
export 'package:onyxia/data/providers/selected_item_provider.dart';
export 'package:onyxia/data/providers/note_state_provider.dart';
export 'package:onyxia/data/providers/canvas_state_provider.dart';
export 'package:onyxia/data/providers/persistence_provider.dart';
export 'package:onyxia/data/providers/diffs_provider.dart';

//packages
export 'package:flutter_riverpod/flutter_riverpod.dart' hide AsyncError;
export 'package:uuid/uuid.dart';
export 'package:go_router/go_router.dart';
export 'package:supabase_flutter/supabase_flutter.dart';
export 'package:contextmenu/contextmenu.dart';
export 'package:flutter_markdown/flutter_markdown.dart';
export 'package:flutter_svg/svg.dart';

//models
export 'package:onyxia/data/models/artifacts/note/note.dart';
export 'package:onyxia/data/models/projects.dart';
export 'package:onyxia/data/models/history/history_diff.dart';
export 'package:onyxia/data/models/history/history_diffs.dart';
export 'package:onyxia/data/models/artifacts/canvas/canvas_model.dart';
export 'package:onyxia/data/models/artifacts/folder/folder.dart';
export 'package:onyxia/data/models/artifacts/canvas/comments.dart';
export 'package:onyxia/data/models/attributes/attribute.dart';
export 'package:onyxia/data/models/attributes/user.dart';
export 'package:onyxia/data/models/user_role.dart';
export 'package:onyxia/data/models/artifacts/canvas/comment.dart';
export 'package:onyxia/data/models/artifacts/canvas/canvas_object.dart';
export 'package:onyxia/data/models/artifacts/canvas/canvas_objects.dart';
export 'package:onyxia/data/models/artifacts/canvas/sub_comment.dart';

export 'package:onyxia/data/models/artifacts/canvas/pin.dart';
export 'package:onyxia/data/models/artifacts/canvas/pins.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/arrow.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/image.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/brush.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/artifact_subobject.dart';
export 'package:onyxia/data/models/artifacts/canvas/user_cursor.dart';
export 'package:onyxia/data/models/project/project.dart';
export 'package:onyxia/data/models/artifacts/artifact_type.dart';
export 'package:onyxia/data/models/artifacts/artifact.dart';

//repositories
export 'package:onyxia/repository/base_supabase_repository.dart';
export 'package:onyxia/repository/auth_repository.dart';
export 'package:onyxia/repository/canvas_cursors_repository.dart';
export 'package:onyxia/repository/canvas_objects_repository.dart';
export 'package:onyxia/repository/comments_repository.dart';
export 'package:onyxia/repository/file_storage.dart' show FileStorage;
export 'package:onyxia/repository/history_diffs_repository.dart';
export 'package:onyxia/repository/projects_repository.dart';
export 'package:onyxia/repository/pins_repository.dart';
export 'package:onyxia/repository/user_definitions_repository.dart';
export 'package:onyxia/repository/user_references_repository.dart';
export 'package:onyxia/repository/artifacts_repository.dart';
export 'package:onyxia/repository/storage_files_repository.dart';

//services
export 'package:onyxia/services/canvas_serializer_service.dart';
export 'package:onyxia/services/note_serializer_service.dart';
export 'package:onyxia/services/images/image_service.dart';
export 'package:onyxia/services/images/image_cache_service.dart';
export 'package:onyxia/services/images/image_encoding_service.dart';
export 'package:onyxia/services/history_service.dart';
export 'package:onyxia/services/timestamp_service.dart';

//helpers
export 'package:onyxia/helpers/color_helper.dart';
export 'package:onyxia/helpers/offset_extension.dart';
export 'package:onyxia/helpers/theme_helper.dart';
//canvas_utils
export 'package:onyxia/presentation/screens/canvas/utils/connection_points.dart';
export 'package:onyxia/presentation/screens/canvas/utils/pathfinder.dart';
export 'package:onyxia/presentation/screens/canvas/utils/arrow_path_helper.dart';
export 'package:onyxia/helpers/image_helper.dart';
export 'package:onyxia/presentation/common_widget/narwhal_spinner.dart';
export 'package:onyxia/helpers/narwhal_enum.dart';

//others
export 'core/abstracts/serializer.dart';
export 'dart:convert';
export 'dart:async';
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart' hide shortHash, describeIdentity;
export 'package:flutter/services.dart';
export 'package:file_picker/file_picker.dart';
export 'package:collection/collection.dart' hide binarySearch, mergeSort;

//vendor
export 'package:super_tree/super_tree.dart';
