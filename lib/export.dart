export 'package:onyxia/presentation/app.dart';

export 'package:onyxia/core/colors.dart';
export 'package:onyxia/core/styles.dart';

export 'package:onyxia/presentation/shell/artifacts_sidebar/artifacts_tree_view.dart';
export 'package:onyxia/presentation/shell/artifacts_sidebar/artifacts_tree_context_menu.dart';
export 'package:onyxia/presentation/shell/artifacts_sidebar/artifacts_sidebar.dart';
export 'package:onyxia/presentation/shell/artifacts_sidebar/artifacts_sidebar_footer.dart';
export 'package:onyxia/presentation/shell/artifacts_sidebar/artifacts_sidebar_header.dart';
export 'package:onyxia/presentation/shell/workspace_host.dart';
export 'package:onyxia/presentation/workspaces/graph/graph_workspace.dart';
export 'package:onyxia/presentation/workspaces/artifact_editor/artifact_editor_workspace.dart';
export 'package:onyxia/presentation/shell/master_sidebar.dart';
export 'package:onyxia/presentation/shell/app_shell.dart';
export 'package:onyxia/presentation/landing/landing_background.dart';
export 'package:onyxia/presentation/landing/landing_overlay.dart';
export 'package:onyxia/presentation/landing/email_auth_form.dart';
export 'package:onyxia/data/models/artifacts/canvas/expandable_pin.dart';

export 'package:onyxia/presentation/common_widget/hover_builder.dart';
export 'package:onyxia/presentation/common_widget/narwhal_drawer_layout.dart';
export 'package:onyxia/presentation/common_widget/onyxia_menu.dart';
export 'package:onyxia/presentation/common_widget/onyxia_overlay.dart';
export 'package:onyxia/presentation/common_widget/narwhal_toast.dart';
export 'package:onyxia/global_error_handler.dart';
export 'package:onyxia/presentation/common_widget/narwhal_modal_dialog.dart';
export 'package:onyxia/presentation/common_widget/onyxia_dialog.dart';
export 'package:onyxia/presentation/shell/artifacts_sidebar/vault_settings_button.dart';
export 'package:onyxia/presentation/shell/vault_members_dialog.dart';
export 'package:onyxia/presentation/common_widget/navigation_url_builder.dart';
export 'package:onyxia/presentation/common_widget/navigation_context_menu.dart';
export 'package:onyxia/presentation/common_widget/drag_select_painter.dart';
export 'package:onyxia/presentation/common_widget/narwhal_paint.dart';
export 'package:onyxia/presentation/common_widget/narwhal_text_style.dart';
export 'package:onyxia/presentation/common_widget/onyxia_icon_button.dart';
export 'package:onyxia/presentation/common_widget/initials_circle.dart';
export 'package:onyxia/presentation/common_widget/onyxia_button.dart';
export 'package:onyxia/services/item_title_validation_service.dart';

export 'package:onyxia/presentation/shell/artifacts_sidebar/tree_tile.dart';

// Editor Views
export 'package:onyxia/presentation/workspaces/artifact_editor/canvas/canvas_editor_view.dart';

export 'package:onyxia/presentation/routing/router.dart';
export 'package:onyxia/presentation/routing/routes.dart';

//data providers
export 'package:onyxia/presentation/routing/providers/auth_provider.dart';
export 'package:onyxia/data/providers/vaults_provider.dart';
export 'package:onyxia/data/providers/current_user_provider.dart';
export 'package:onyxia/data/providers/vault_members_provider.dart';
export 'package:onyxia/data/providers/vault_invitations_provider.dart';
export 'package:onyxia/data/providers/artifacts_provider.dart';
export 'package:onyxia/data/providers/selected_artifact_provider.dart';
export 'package:onyxia/data/providers/selected_vault_provider.dart';
export 'package:onyxia/data/providers/note_state_provider.dart';

//packages
export 'package:flutter_riverpod/flutter_riverpod.dart' hide AsyncError;
export 'package:uuid/uuid.dart';
export 'package:go_router/go_router.dart';
export 'package:supabase_flutter/supabase_flutter.dart' hide User;
export 'package:lucide_icons_flutter/lucide_icons.dart';
export 'package:super_tree/super_tree.dart';
export 'package:file_picker/file_picker.dart';
export 'package:collection/collection.dart' hide binarySearch, mergeSort;
export 'package:gap/gap.dart';
export 'package:flutter_portal/flutter_portal.dart';

//models
export 'package:onyxia/data/models/artifacts/note_artifact.dart';
export 'package:onyxia/data/models/artifacts/canvas/canvas_artifact.dart';
export 'package:onyxia/data/models/artifacts/folder_artifact.dart';
export 'package:onyxia/data/models/artifacts/image_artifact.dart';
export 'package:onyxia/data/models/user.dart';
export 'package:onyxia/data/models/vault_member.dart';
export 'package:onyxia/data/models/vault_invitation.dart';
export 'package:onyxia/data/models/artifacts/canvas/comment.dart';
export 'package:onyxia/data/models/artifacts/canvas/canvas_object.dart';
export 'package:onyxia/data/models/artifacts/canvas/sub_comment.dart';
export 'package:onyxia/data/models/artifacts/canvas/pin.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/arrow.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/image.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/brush.dart';
export 'package:onyxia/data/models/artifacts/canvas/subobjects/artifact_subobject.dart';
export 'package:onyxia/data/models/vault.dart';
export 'package:onyxia/data/models/artifacts/artifact.dart';
export 'package:onyxia/data/models/artifact_op.dart';
export 'package:onyxia/data/models/artifact_snapshot.dart';

//repositories
export 'package:onyxia/repository/base_supabase_repository.dart';
export 'package:onyxia/repository/auth_repository.dart';
export 'package:onyxia/repository/canvas_objects_repository.dart';
export 'package:onyxia/repository/comments_repository.dart';
export 'package:onyxia/repository/vaults_repository.dart';
export 'package:onyxia/repository/pins_repository.dart';
export 'package:onyxia/repository/users_repository.dart';
export 'package:onyxia/repository/vault_members_repository.dart';
export 'package:onyxia/repository/vault_invitations_repository.dart';
export 'package:onyxia/repository/artifacts_repository.dart';
export 'package:onyxia/repository/artifact_ops_repository.dart';
export 'package:onyxia/repository/artifact_snapshots_repository.dart';

//services
export 'package:onyxia/services/image_service.dart';
export 'package:onyxia/services/porting_service.dart';
export 'package:onyxia/services/timestamp_service.dart';

//bard
export 'package:onyxia/bard/bard_codec.dart';

//helpers
export 'package:onyxia/helpers/offset_extension.dart';
export 'package:onyxia/helpers/theme_helper.dart';
//canvas_utils
export 'package:onyxia/presentation/canvas_engine/utils/connection_points.dart';
export 'package:onyxia/presentation/canvas_engine/utils/pathfinder.dart';
export 'package:onyxia/presentation/canvas_engine/utils/arrow_path_helper.dart';
export 'package:onyxia/helpers/image_helper.dart';
export 'package:onyxia/presentation/common_widget/onyxia_loading_indicator.dart';
export 'package:onyxia/helpers/narwhal_enum.dart';

//others
export 'package:flutter/material.dart';
export 'package:flutter/foundation.dart' hide shortHash, describeIdentity;
export 'package:flutter/services.dart';
