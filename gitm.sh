#!/bin/bash

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NO_COLOR='\033[0m'

# Mengaktifkan exit segera jika ada perintah yang gagal
set -e

LOG_FILE="git_manager.log"

# Fungsi untuk mencatat log aktivitas
log_activity() {
    echo "$(date "+%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Fungsi untuk memeriksa ketersediaan Git
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Git tidak ditemukan. Silakan install Git terlebih dahulu.${NO_COLOR}"
        log_activity "ERROR: Git not found."
        exit 1
    fi
}

# Fungsi untuk memeriksa apakah berada di dalam repositori Git
check_in_git_repo() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        echo -e "${RED}Error: Anda tidak berada di dalam repositori Git. Silakan navigasi ke folder proyek Anda terlebih dahulu.${NO_COLOR}"
        log_activity "ERROR: Not in a Git repository for current operation."
        return 1
    fi
    return 0
}

# Fungsi untuk menampilkan header
display_header() {
    clear
    echo -e "${BLUE}=========================================${NO_COLOR}"
    echo -e "${GREEN}          Git Manager Script            ${NO_COLOR}"
    echo -e "${BLUE}=========================================${NO_COLOR}"
}

# Fungsi untuk menampilkan menu
show_menu() {
    display_header
    echo -e "${YELLOW}1. Clone Repository${NO_COLOR}"
    echo -e "${YELLOW}2. Create & Switch Branch${NO_COLOR}"
    echo -e "${YELLOW}3. Switch Branch${NO_COLOR}"
    echo -e "${YELLOW}4. Commit Changes${NO_COLOR}"
    echo -e "${YELLOW}5. Push Changes${NO_COLOR}"
    echo -e "${YELLOW}6. Show Git Status${NO_COLOR}"
    echo -e "${YELLOW}7. Show Commit Log${NO_COLOR}"
    echo -e "${YELLOW}8. Add Remote${NO_COLOR}"
    echo -e "${YELLOW}9. Update Repository (Fetch & Pull)${NO_COLOR}"
    echo -e "${YELLOW}10. Merge Branch${NO_COLOR}"
    echo -e "${YELLOW}11. Delete Branch${NO_COLOR}"
    echo -e "${YELLOW}12. Create Tag${NO_COLOR}"
    echo -e "${YELLOW}13. Show Branch List${NO_COLOR}"
    echo -e "${YELLOW}14. Rebase Branch${NO_COLOR}"
    echo -e "${YELLOW}15. Show Remotes${NO_COLOR}"
    echo -e "${YELLOW}16. Show Tags${NO_COLOR}"
    echo -e "${YELLOW}17. Stash Management${NO_COLOR}"
    echo -e "${YELLOW}18. Show Diff (Changes)${NO_COLOR}"
    echo -e "${YELLOW}19. Reset Changes / Commits${NO_COLOR}"
    echo -e "${YELLOW}20. Revert a Commit${NO_COLOR}"
    echo -e "${YELLOW}21. Clean Untracked Files${NO_COLOR}"
    echo -e "${YELLOW}22. Manage .gitignore${NO_COLOR}"
    echo -e "${YELLOW}23. Help${NO_COLOR}"
    echo -e "${YELLOW}24. Exit${NO_COLOR}"
    echo -n -e "${BLUE}Select an option [1-24]: ${NO_COLOR}"
}

# Fungsi untuk menampilkan status branch saat ini
show_current_branch_status() {
    if ! check_in_git_repo; then return; fi
    local branch_name=$(git rev-parse --abbrev-ref HEAD)
    local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    
    echo -e "${CYAN}Current Branch: ${branch_name}${NO_COLOR}"
    
    if [ -n "$remote_branch" ]; then
        local ahead_behind=$(git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
        if [ -n "$ahead_behind" ]; then
            local ahead=$(echo "$ahead_behind" | awk '{print $1}')
            local behind=$(echo "$ahead_behind" | awk '{print $2}')
            
            if [ "$ahead" -gt 0 ]; then
                echo -e "${CYAN}Commits to push: ${ahead}${NO_COLOR}"
            fi
            if [ "$behind" -gt 0 ]; then
                echo -e "${CYAN}Commits to pull: ${behind}${NO_COLOR}"
            fi
        fi
    else
        echo -e "${YELLOW}No upstream branch set for '${branch_name}'.${NO_COLOR}"
    fi
}

# Fungsi untuk meng-clone repositori
clone_repository() {
    read -p "Enter repository URL: " repo_url
    if [[ -z "$repo_url" ]]; then
        echo -e "${RED}URL tidak boleh kosong.${NO_COLOR}"
        return
    fi

    read -p "Enter local directory name (optional, leave empty for default): " dir_name
    
    if [[ -z "$dir_name" ]]; then
        git clone "$repo_url" && echo -e "${GREEN}Repository cloned successfully!${NO_COLOR}" && log_activity "Cloned repository from $repo_url" || { echo -e "${RED}Failed to clone repository.${NO_COLOR}"; return; }
    else
        git clone "$repo_url" "$dir_name" && echo -e "${GREEN}Repository cloned successfully into '$dir_name'!${NO_COLOR}" && log_activity "Cloned repository from $repo_url into $dir_name" || { echo -e "${RED}Failed to clone repository into '$dir_name'.${NO_COLOR}"; return; }
    fi
    echo -e "${YELLOW}Anda mungkin perlu masuk ke direktori baru: cd ${dir_name:-$(basename "$repo_url" .git)}${NO_COLOR}"
    read -p "Press Enter to continue..."
}

# Fungsi untuk membuat dan berpindah ke branch baru
create_and_switch_branch() {
    if ! check_in_git_repo; then return; fi
    read -p "Enter new branch name: " branch_name
    if [[ -z "$branch_name" ]]; then
        echo -e "${RED}Nama branch tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if git rev-parse --verify "$branch_name" &> /dev/null; then
        echo -e "${RED}Branch '$branch_name' sudah ada. Silakan pilih nama lain atau gunakan 'Switch Branch'.${NO_COLOR}"
        return
    fi
    git checkout -b "$branch_name" && echo -e "${GREEN}Branch '$branch_name' created and checked out!${NO_COLOR}" && log_activity "Created new branch '$branch_name'" || { echo -e "${RED}Failed to create branch '$branch_name'.${NO_COLOR}"; return; }
    read -p "Press Enter to continue..."
}

# Fungsi untuk berpindah branch
switch_branch() {
    if ! check_in_git_repo; then return; fi
    show_branches_internal # Panggil fungsi internal untuk menampilkan daftar branch
    read -p "Enter branch name to switch to: " branch_name
    if [[ -z "$branch_name" ]]; then
        echo -e "${RED}Nama branch tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if ! git rev-parse --verify "$branch_name" &> /dev/null; then
        echo -e "${RED}Branch '$branch_name' tidak ditemukan.${NO_COLOR}"
        return
    fi
    git checkout "$branch_name" && echo -e "${GREEN}Switched to branch '$branch_name'!${NO_COLOR}" && log_activity "Switched to branch '$branch_name'" || { echo -e "${RED}Failed to switch to branch '$branch_name'.${NO_COLOR}"; return; }
    read -p "Press Enter to continue..."
}

# Fungsi untuk melakukan commit
commit_changes() {
    if ! check_in_git_repo; then return; fi

    if [[ -z $(git status --porcelain) ]]; then
        echo -e "${YELLOW}Tidak ada perubahan yang perlu di-commit.${NO_COLOR}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${YELLOW}Perubahan yang ada:${NO_COLOR}"
    git status --short

    read -p "Tambahkan semua perubahan (git add .)? (y/N): " add_all_confirm
    if [[ "$add_all_confirm" =~ ^[Yy]$ ]]; then
        git add .
        echo -e "${GREEN}Semua perubahan ditambahkan ke staging area.${NO_COLOR}"
    else
        echo -e "${YELLOW}Perubahan tidak ditambahkan. Silakan tambahkan secara manual jika diperlukan.${NO_COLOR}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Enter commit message: " commit_message
    if [[ -z "$commit_message" ]]; then
        echo -e "${RED}Pesan commit tidak boleh kosong.${NO_COLOR}"
        return
    fi
    git commit -m "$commit_message" && echo -e "${GREEN}Changes committed successfully!${NO_COLOR}" && log_activity "Committed changes with message: '$commit_message'" || { echo -e "${RED}Failed to commit changes.${NO_COLOR}"; return; }
    read -p "Press Enter to continue..."
}

# Fungsi untuk push perubahan
push_changes() {
    if ! check_in_git_repo; then return; fi

    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    local remote_name=$(git remote show | head -n 1) # Ambil remote pertama sebagai default

    # Cek apakah ada commit yang belum di-push
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} &> /dev/null; then
        if [[ $(git rev-list --count HEAD@{upstream}..HEAD) -eq 0 ]]; then
            echo -e "${YELLOW}Tidak ada commit baru untuk di-push.${NO_COLOR}"
            read -p "Press Enter to continue..."
            return
        fi
    fi

    read -p "Enter remote name (default: $remote_name): " chosen_remote
    if [[ -z "$chosen_remote" ]]; then
        chosen_remote="$remote_name"
    fi
    if ! git remote get-url "$chosen_remote" &> /dev/null; then
        echo -e "${RED}Remote '$chosen_remote' tidak ditemukan.${NO_COLOR}"
        return
    fi

    read -p "Enter branch name to push (default: $current_branch): " chosen_branch
    if [[ -z "$chosen_branch" ]]; then
        chosen_branch="$current_branch"
    fi
    # Pastikan branch lokal yang dipilih ada
    if ! git rev-parse --verify "$chosen_branch" &> /dev/null; then
        echo -e "${RED}Branch lokal '$chosen_branch' tidak ditemukan.${NO_COLOR}"
        return
    fi

    # Cek apakah upstream sudah diatur
    if ! git rev-parse --abbrev-ref --symbolic-full-name "$chosen_branch@{u}" &> /dev/null; then
        read -p "Upstream branch untuk '$chosen_branch' belum diatur. Set upstream (git push -u $chosen_remote $chosen_branch)? (y/N): " set_upstream_confirm
        if [[ "$set_upstream_confirm" =~ ^[Yy]$ ]]; then
            git push -u "$chosen_remote" "$chosen_branch" && echo -e "${GREEN}Changes pushed and upstream set to '$chosen_remote/$chosen_branch'!${NO_COLOR}" && log_activity "Pushed changes and set upstream to '$chosen_remote/$chosen_branch'" || { echo -e "${RED}Failed to push changes.${NO_COLOR}"; return; }
        else
            git push "$chosen_remote" "$chosen_branch" && echo -e "${GREEN}Changes pushed to '$chosen_branch' on '$chosen_remote'!${NO_COLOR}" && log_activity "Pushed changes to '$chosen_branch' on '$chosen_remote'" || { echo -e "${RED}Failed to push changes.${NO_COLOR}"; return; }
        fi
    else
        git push "$chosen_remote" "$chosen_branch" && echo -e "${GREEN}Changes pushed to '$chosen_branch' on '$chosen_remote'!${NO_COLOR}" && log_activity "Pushed changes to '$chosen_branch' on '$chosen_remote'" || { echo -e "${RED}Failed to push changes.${NO_COLOR}"; return; }
    fi

    read -p "Do you want to push all tags? (y/N): " push_tags_confirm
    if [[ "$push_tags_confirm" =~ ^[Yy]$ ]]; then
        git push "$chosen_remote" --tags && echo -e "${GREEN}All tags pushed to '$chosen_remote'!${NO_COLOR}" || { echo -e "${RED}Failed to push tags.${NO_COLOR}"; return; }
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan status Git
show_status() {
    if ! check_in_git_repo; then return; fi
    show_current_branch_status
    echo -e "${YELLOW}==========================${NO_COLOR}"
    git status
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan commit log
show_log() {
    if ! check_in_git_repo; then return; fi
    git log --oneline --graph --decorate --all
    read -p "Press Enter to continue..."
}

# Fungsi untuk menambah remote
add_remote() {
    if ! check_in_git_repo; then return; fi
    read -p "Enter remote name (e.g., origin, upstream): " remote_name
    if [[ -z "$remote_name" ]]; then
        echo -e "${RED}Nama remote tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if git remote get-url "$remote_name" &> /dev/null; then
        echo -e "${RED}Remote '$remote_name' sudah ada.${NO_COLOR}"
        return
    fi
    read -p "Enter remote URL: " remote_url
    if [[ -z "$remote_url" ]]; then
        echo -e "${RED}URL remote tidak boleh kosong.${NO_COLOR}"
        return
    fi
    git remote add "$remote_name" "$remote_url" && echo -e "${GREEN}Remote '$remote_name' added successfully!${NO_COLOR}" && log_activity "Added remote '$remote_name'" || { echo -e "${RED}Failed to add remote '$remote_name'.${NO_COLOR}"; return; }
    read -p "Press Enter to continue..."
}

# Fungsi untuk memperbarui repositori (fetch dan pull)
update_repository() {
    if ! check_in_git_repo; then return; fi
    echo -e "${YELLOW}Fetching all remotes...${NO_COLOR}"
    git fetch --all && echo -e "${GREEN}Fetch complete.${NO_COLOR}" || { echo -e "${RED}Failed to fetch updates.${NO_COLOR}"; return; }

    echo -e "${YELLOW}Pulling changes into current branch...${NO_COLOR}"
    if git pull; then
        echo -e "${GREEN}Repository updated successfully!${NO_COLOR}"
        log_activity "Updated repository"
    else
        echo -e "${RED}Failed to update the repository. Konflik mungkin terjadi.${NO_COLOR}"
        echo -e "${YELLOW}Silakan selesaikan konflik secara manual, lalu commit perubahan atau batalkan merge dengan 'git merge --abort'.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk menggabungkan branch
merge_branch() {
    if ! check_in_git_repo; then return; fi
    show_branches_internal
    read -p "Enter branch name to merge into current branch: " branch_name
    if [[ -z "$branch_name" ]]; then
        echo -e "${RED}Nama branch tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if ! git rev-parse --verify "$branch_name" &> /dev/null; then
        echo -e "${RED}Branch '$branch_name' tidak ditemukan.${NO_COLOR}"
        return
    fi

    echo -e "${YELLOW}Attempting to merge '$branch_name' into $(git rev-parse --abbrev-ref HEAD)...${NO_COLOR}"
    if git merge "$branch_name"; then
        echo -e "${GREEN}Merged branch '$branch_name' successfully!${NO_COLOR}"
        log_activity "Merged branch '$branch_name'"
    else
        echo -e "${RED}Failed to merge branch '$branch_name'. Konflik terjadi.${NO_COLOR}"
        echo -e "${YELLOW}Silakan selesaikan konflik secara manual, lalu commit perubahan atau batalkan merge dengan 'git merge --abort'.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk menghapus branch
delete_branch() {
    if ! check_in_git_repo; then return; fi
    show_branches_internal
    read -p "Enter branch name to delete: " branch_name
    if [[ -z "$branch_name" ]]; then
        echo -e "${RED}Nama branch tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if ! git rev-parse --verify "$branch_name" &> /dev/null; then
        echo -e "${RED}Branch '$branch_name' tidak ditemukan.${NO_COLOR}"
        return
    fi
    
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$branch_name" == "$current_branch" ]]; then
        echo -e "${RED}Anda tidak bisa menghapus branch yang sedang aktif. Silakan pindah ke branch lain terlebih dahulu.${NO_COLOR}"
        read -p "Press Enter to continue..."
        return
    fi

    read -p "Are you sure you want to delete branch '$branch_name'? This action is irreversible. (y/N): " confirm_delete
    if [[ "$confirm_delete" =~ ^[Yy]$ ]]; then
        if git branch -d "$branch_name"; then
            echo -e "${GREEN}Branch '$branch_name' deleted successfully!${NO_COLOR}"
            log_activity "Deleted branch '$branch_name'"
        else
            read -p "Branch '$branch_name' belum sepenuhnya di-merge. Force delete? (y/N): " force_delete_confirm
            if [[ "$force_delete_confirm" =~ ^[Yy]$ ]]; then
                git branch -D "$branch_name" && echo -e "${GREEN}Branch '$branch_name' force deleted successfully!${NO_COLOR}" && log_activity "Force deleted branch '$branch_name'" || { echo -e "${RED}Failed to force delete branch '$branch_name'.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Branch deletion cancelled.${NO_COLOR}"
            fi
        fi
    else
        echo -e "${YELLOW}Branch deletion cancelled.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk membuat tag
create_tag() {
    if ! check_in_git_repo; then return; fi
    read -p "Enter tag name: " tag_name
    if [[ -z "$tag_name" ]]; then
        echo -e "${RED}Nama tag tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if git rev-parse --verify "refs/tags/$tag_name" &> /dev/null; then
        echo -e "${RED}Tag '$tag_name' sudah ada.${NO_COLOR}"
        return
    fi
    read -p "Enter tag message (optional, for annotated tag): " tag_message

    if [[ -z "$tag_message" ]]; then
        git tag "$tag_name" && echo -e "${GREEN}Tag '$tag_name' (lightweight) created successfully!${NO_COLOR}" && log_activity "Created lightweight tag '$tag_name'" || { echo -e "${RED}Failed to create tag '$tag_name'.${NO_COLOR}"; return; }
    else
        git tag -a "$tag_name" -m "$tag_message" && echo -e "${GREEN}Annotated tag '$tag_name' created successfully!${NO_COLOR}" && log_activity "Created annotated tag '$tag_name'" || { echo -e "${RED}Failed to create annotated tag '$tag_name'.${NO_COLOR}"; return; }
    fi
    read -p "Press Enter to continue..."
}

# Fungsi internal untuk menampilkan daftar branch (digunakan oleh fungsi lain)
show_branches_internal() {
    echo -e "${BLUE}Branches in the repository:${NO_COLOR}"
    git branch -v
}

# Fungsi untuk menampilkan daftar branch (untuk opsi menu)
show_branches() {
    if ! check_in_git_repo; then return; fi
    show_branches_internal
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan daftar remote
show_remotes() {
    if ! check_in_git_repo; then return; fi
    echo -e "${BLUE}Configured Remotes:${NO_COLOR}"
    git remote -v
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan daftar tag
show_tags() {
    if ! check_in_git_repo; then return; fi
    echo -e "${BLUE}Tags in the repository:${NO_COLOR}"
    git tag --list
    read -p "Press Enter to continue..."
}

# Fungsi untuk melakukan rebase
rebase_branch() {
    if ! check_in_git_repo; then return; fi
    show_branches_internal
    read -p "Enter branch name to rebase onto (e.g., main, develop): " target_branch
    if [[ -z "$target_branch" ]]; then
        echo -e "${RED}Nama branch target tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if ! git rev-parse --verify "$target_branch" &> /dev/null; then
        echo -e "${RED}Branch '$target_branch' tidak ditemukan.${NO_COLOR}"
        return
    fi

    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ "$target_branch" == "$current_branch" ]]; then
        echo -e "${RED}Anda tidak bisa merebase branch ke dirinya sendiri.${NO_COLOR}"
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${YELLOW}Rebasing '$current_branch' onto '$target_branch'...${NO_COLOR}"
    if git rebase "$target_branch"; then
        echo -e "${GREEN}Rebased onto '$target_branch' successfully!${NO_COLOR}"
        log_activity "Rebased '$current_branch' onto '$target_branch'"
    else
        echo -e "${RED}Failed to rebase onto '$target_branch'. Konflik terjadi.${NO_COLOR}"
        echo -e "${YELLOW}Silakan selesaikan konflik secara manual, lalu lanjutkan dengan 'git rebase --continue' atau batalkan dengan 'git rebase --abort'.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk manajemen stash
stash_management() {
    if ! check_in_git_repo; then return; fi
    echo -e "${BLUE}=== Git Stash Management ===${NO_COLOR}"
    git stash list

    echo -e "${YELLOW}1. Stash Current Changes${NO_COLOR}"
    echo -e "${YELLOW}2. Apply a Stash${NO_COLOR}"
    echo -e "${YELLOW}3. Pop a Stash (Apply and Drop)${NO_COLOR}"
    echo -e "${YELLOW}4. Drop a Stash${NO_COLOR}"
    echo -e "${YELLOW}5. Clear All Stashes${NO_COLOR}"
    echo -e "${YELLOW}6. Back to Main Menu${NO_COLOR}"
    echo -n -e "${BLUE}Select a stash option [1-6]: ${NO_COLOR}"
    read -r stash_option

    case $stash_option in
        1)
            if [[ -z $(git status --porcelain) ]]; then
                echo -e "${YELLOW}Tidak ada perubahan untuk di-stash.${NO_COLOR}"
                read -p "Press Enter to continue..."
                return
            fi
            read -p "Enter stash message (optional): " stash_message
            if [[ -z "$stash_message" ]]; then
                git stash && echo -e "${GREEN}Changes stashed successfully!${NO_COLOR}" && log_activity "Stashed changes" || { echo -e "${RED}Failed to stash changes.${NO_COLOR}"; return; }
            else
                git stash save "$stash_message" && echo -e "${GREEN}Changes stashed successfully with message: '$stash_message'!${NO_COLOR}" && log_activity "Stashed changes with message: '$stash_message'" || { echo -e "${RED}Failed to stash changes.${NO_COLOR}"; return; }
            fi
            ;;
        2)
            read -p "Enter stash index to apply (e.g., 0 for stash@{0}): " stash_index
            if [[ -z "$stash_index" || ! "$stash_index" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Input tidak valid. Harap masukkan angka.${NO_COLOR}"
                return
            fi
            if git stash apply "stash@{$stash_index}"; then
                echo -e "${GREEN}Stash stash@{$stash_index} applied successfully!${NO_COLOR}"
                log_activity "Applied stash stash@{$stash_index}"
            else
                echo -e "${RED}Gagal menerapkan stash stash@{$stash_index}. Mungkin ada konflik.${NO_COLOR}"
            fi
            ;;
        3)
            read -p "Enter stash index to pop (e.g., 0 for stash@{0}): " stash_index
            if [[ -z "$stash_index" || ! "$stash_index" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Input tidak valid. Harap masukkan angka.${NO_COLOR}"
                return
            fi
            if git stash pop "stash@{$stash_index}"; then
                echo -e "${GREEN}Stash stash@{$stash_index} popped successfully!${NO_COLOR}"
                log_activity "Popped stash stash@{$stash_index}"
            else
                echo -e "${RED}Gagal mempop stash stash@{$stash_index}. Mungkin ada konflik.${NO_COLOR}"
            fi
            ;;
        4)
            read -p "Enter stash index to drop (e.g., 0 for stash@{0}): " stash_index
            if [[ -z "$stash_index" || ! "$stash_index" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Input tidak valid. Harap masukkan angka.${NO_COLOR}"
                return
            fi
            read -p "Are you sure you want to drop stash@{$stash_index}? (y/N): " confirm_drop
            if [[ "$confirm_drop" =~ ^[Yy]$ ]]; then
                git stash drop "stash@{$stash_index}" && echo -e "${GREEN}Stash stash@{$stash_index} dropped successfully!${NO_COLOR}" && log_activity "Dropped stash stash@{$stash_index}" || { echo -e "${RED}Failed to drop stash@{$stash_index}.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Stash drop cancelled.${NO_COLOR}"
            fi
            ;;
        5)
            read -p "Are you sure you want to CLEAR ALL stashes? This is irreversible! (y/N): " confirm_clear
            if [[ "$confirm_clear" =~ ^[Yy]$ ]]; then
                git stash clear && echo -e "${GREEN}All stashes cleared successfully!${NO_COLOR}" && log_activity "Cleared all stashes" || { echo -e "${RED}Failed to clear all stashes.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Stash clear cancelled.${NO_COLOR}"
            fi
            ;;
        6)
            echo -e "${YELLOW}Returning to main menu.${NO_COLOR}"
            ;;
        *) echo -e "${RED}Invalid option. Please try again.${NO_COLOR}" ;;
    esac
    read -p "Press Enter to continue..."
}

# Fungsi untuk menampilkan perbedaan perubahan
show_diff() {
    if ! check_in_git_repo; then return; fi
    echo -e "${YELLOW}Menampilkan perbedaan perubahan (unstaged):${NO_COLOR}"
    git diff
    echo -e "${YELLOW}-----------------------------------${NO_COLOR}"
    echo -e "${YELLOW}Menampilkan perbedaan perubahan yang sudah di-stage:${NO_COLOR}"
    git diff --staged
    read -p "Press Enter to continue..."
}

# Fungsi untuk mereset perubahan atau commit
reset_changes() {
    if ! check_in_git_repo; then return; fi
    echo -e "${BLUE}=== Git Reset Options ===${NO_COLOR}"
    echo -e "${YELLOW}1. Reset --soft (Uncommit, keep changes staged)${NO_COLOR}"
    echo -e "${YELLOW}2. Reset --mixed (Uncommit, unstage, keep working directory)${NO_COLOR}"
    echo -e "${YELLOW}3. Reset --hard (Uncommit, unstage, DISCARD all changes)${NO_COLOR}"
    echo -e "${YELLOW}4. Reset a Specific File to last committed state${NO_COLOR}"
    echo -e "${YELLOW}5. Back to Main Menu${NO_COLOR}"
    echo -n -e "${BLUE}Select a reset option [1-5]: ${NO_COLOR}"
    read -r reset_option

    case $reset_option in
        1)
            read -p "Enter commit hash or HEAD~N (e.g., HEAD~1 to uncommit last): " target_ref
            if [[ -z "$target_ref" ]]; then
                echo -e "${RED}Input tidak boleh kosong.${NO_COLOR}"
                return
            fi
            read -p "Are you sure you want to 'git reset --soft $target_ref'? (y/N): " confirm_reset
            if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
                git reset --soft "$target_ref" && echo -e "${GREEN}Soft reset successful! Changes are staged.${NO_COLOR}" && log_activity "Soft reset to $target_ref" || { echo -e "${RED}Failed to soft reset.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Reset cancelled.${NO_COLOR}"
            fi
            ;;
        2)
            read -p "Enter commit hash or HEAD~N (e.g., HEAD~1 to uncommit last): " target_ref
            if [[ -z "$target_ref" ]]; then
                echo -e "${RED}Input tidak boleh kosong.${NO_COLOR}"
                return
            fi
            read -p "Are you sure you want to 'git reset --mixed $target_ref'? (y/N): " confirm_reset
            if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
                git reset --mixed "$target_ref" && echo -e "${GREEN}Mixed reset successful! Changes are unstaged.${NO_COLOR}" && log_activity "Mixed reset to $target_ref" || { echo -e "${RED}Failed to mixed reset.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Reset cancelled.${NO_COLOR}"
            fi
            ;;
        3)
            read -p "Enter commit hash or HEAD~N (e.g., HEAD~1 to discard last commit changes): " target_ref
            if [[ -z "$target_ref" ]]; then
                echo -e "${RED}Input tidak boleh kosong.${NO_COLOR}"
                return
            fi
            echo -e "${RED}WARNING: 'git reset --hard' AKAN MENGHAPUS SEMUA PERUBAHAN YANG TIDAK DI-COMMIT!${NO_COLOR}"
            read -p "Are you ABSOLUTELY sure you want to 'git reset --hard $target_ref'? (y/N): " confirm_hard_reset
            if [[ "$confirm_hard_reset" =~ ^[Yy]$ ]]; then
                git reset --hard "$target_ref" && echo -e "${GREEN}Hard reset successful! All changes discarded.${NO_COLOR}" && log_activity "Hard reset to $target_ref" || { echo -e "${RED}Failed to hard reset.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}Hard reset cancelled.${NO_COLOR}"
            fi
            ;;
        4)
            read -p "Enter file path to reset to last committed state: " file_path
            if [[ -z "$file_path" ]]; then
                echo -e "${RED}Path file tidak boleh kosong.${NO_COLOR}"
                return
            fi
            if ! [ -f "$file_path" ]; then
                echo -e "${RED}File '$file_path' tidak ditemukan.${NO_COLOR}"
                return
            fi
            read -p "Are you sure you want to reset '$file_path' to its last committed state? (y/N): " confirm_file_reset
            if [[ "$confirm_file_reset" =~ ^[Yy]$ ]]; then
                git checkout -- "$file_path" && echo -e "${GREEN}File '$file_path' reset successfully!${NO_COLOR}" && log_activity "Reset file $file_path" || { echo -e "${RED}Failed to reset file '$file_path'.${NO_COLOR}"; return; }
            else
                echo -e "${YELLOW}File reset cancelled.${NO_COLOR}"
            fi
            ;;
        5)
            echo -e "${YELLOW}Returning to main menu.${NO_COLOR}"
            ;;
        *) echo -e "${RED}Invalid option. Please try again.${NO_COLOR}" ;;
    esac
    read -p "Press Enter to continue..."
}

# Fungsi untuk revert commit
revert_commit() {
    if ! check_in_git_repo; then return; fi
    echo -e "${YELLOW}Recent commits:${NO_COLOR}"
    git log --oneline -5 # Tampilkan 5 commit terakhir

    read -p "Enter commit hash to revert (e.g., abc1234): " commit_hash
    if [[ -z "$commit_hash" ]]; then
        echo -e "${RED}Commit hash tidak boleh kosong.${NO_COLOR}"
        return
    fi
    if ! git rev-parse --verify "$commit_hash" &> /dev/null; then
        echo -e "${RED}Commit '$commit_hash' tidak ditemukan.${NO_COLOR}"
        return
    fi

    read -p "Are you sure you want to revert commit '$commit_hash'? This will create a new commit. (y/N): " confirm_revert
    if [[ "$confirm_revert" =~ ^[Yy]$ ]]; then
        if git revert "$commit_hash"; then
            echo -e "${GREEN}Commit '$commit_hash' reverted successfully! A new commit has been created.${NO_COLOR}"
            log_activity "Reverted commit $commit_hash"
        else
            echo -e "${RED}Failed to revert commit '$commit_hash'. Konflik mungkin terjadi.${NO_COLOR}"
            echo -e "${YELLOW}Silakan selesaikan konflik secara manual, lalu commit perubahan atau batalkan revert dengan 'git revert --abort'.${NO_COLOR}"
        fi
    else
        echo -e "${YELLOW}Revert cancelled.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk membersihkan file yang tidak terlacak
clean_untracked_files() {
    if ! check_in_git_repo; then return; fi
    echo -e "${RED}WARNING: Ini akan menghapus file dan direktori yang tidak terlacak dari working directory Anda!${NO_COLOR}"
    echo -e "${YELLOW}Berikut adalah file dan direktori yang akan dihapus (dry run):${NO_COLOR}"
    git clean -n -d

    read -p "Apakah Anda yakin ingin melanjutkan dan menghapus file dan direktori yang tidak terlacak? (y/N): " confirm_clean
    if [[ "$confirm_clean" =~ ^[Yy]$ ]]; then
        read -p "KONFIRMASI TERAKHIR: Ini tidak dapat diurungkan! Hapus sekarang? (y/N): " final_confirm_clean
        if [[ "$final_confirm_clean" =~ ^[Yy]$ ]]; then
            git clean -f -d && echo -e "${GREEN}Untracked files and directories cleaned successfully!${NO_COLOR}" && log_activity "Cleaned untracked files" || { echo -e "${RED}Failed to clean untracked files.${NO_COLOR}"; return; }
        else
            echo -e "${YELLOW}Clean operation cancelled.${NO_COLOR}"
        fi
    else
        echo -e "${YELLOW}Clean operation cancelled.${NO_COLOR}"
    fi
    read -p "Press Enter to continue..."
}

# Fungsi untuk mengelola .gitignore
manage_gitignore() {
    if ! check_in_git_repo; then return; fi
    local gitignore_file=".gitignore"

    echo -e "${BLUE}=== Manage .gitignore ===${NO_COLOR}"
    if [ -f "$gitignore_file" ]; then
        echo -e "${YELLOW}Current .gitignore content:${NO_COLOR}"
        cat "$gitignore_file"
    else
        echo -e "${YELLOW}No .gitignore file found. A new one will be created if you add entries.${NO_COLOR}"
    fi

    echo -e "${YELLOW}1. Add an entry to .gitignore${NO_COLOR}"
    echo -e "${YELLOW}2. View .gitignore content${NO_COLOR}"
    echo -e "${YELLOW}3. Back to Main Menu${NO_COLOR}"
    echo -n -e "${BLUE}Select a .gitignore option [1-3]: ${NO_COLOR}"
    read -r gitignore_option

    case $gitignore_option in
        1)
            read -p "Enter pattern to add (e.g., *.log, build/, temp.txt): " pattern_to_add
            if [[ -z "$pattern_to_add" ]]; then
                echo -e "${RED}Pola tidak boleh kosong.${NO_COLOR}"
                return
            fi
            # Cek apakah pola sudah ada di .gitignore
            if grep -qF "$pattern_to_add" "$gitignore_file" 2>/dev/null; then
                echo -e "${YELLOW}Pola '$pattern_to_add' sudah ada di .gitignore.${NO_COLOR}"
            else
                echo "$pattern_to_add" >> "$gitignore_file" && echo -e "${GREEN}Pattern '$pattern_to_add' added to .gitignore!${NO_COLOR}" && log_activity "Added '$pattern_to_add' to .gitignore" || { echo -e "${RED}Failed to add pattern to .gitignore.${NO_COLOR}"; return; }
            fi
            ;;
        2)
            if [ -f "$gitignore_file" ]; then
                echo -e "${YELLOW}Current .gitignore content:${NO_COLOR}"
                cat "$gitignore_file"
            else
                echo -e "${YELLOW}No .gitignore file found.${NO_COLOR}"
            fi
            ;;
        3)
            echo -e "${YELLOW}Returning to main menu.${NO_COLOR}"
            ;;
        *) echo -e "${RED}Invalid option. Please try again.${NO_COLOR}" ;;
    esac
    read -p "Press Enter to continue..."
}


# Fungsi untuk menampilkan bantuan
show_help() {
    echo -e "${YELLOW}Available Commands:${NO_COLOR}"
    echo " 1. Clone Repository: Clone a repository from a URL into a local directory."
    echo " 2. Create & Switch Branch: Create a new branch and immediately switch to it."
    echo " 3. Switch Branch: Switch to an existing branch."
    echo " 4. Commit Changes: Stage all current changes and commit them with a message."
    echo " 5. Push Changes: Push committed changes from your local branch to the remote."
    echo " 6. Show Git Status: Display the status of your working directory (modified, staged, untracked files)."
    echo " 7. Show Commit Log: View the commit history of the repository."
    echo " 8. Add Remote: Add a new remote repository (e.g., 'upstream') to your local setup."
    echo " 9. Update Repository: Fetch all updates from remotes and pull changes into the current branch."
    echo "10. Merge Branch: Integrate changes from another branch into your current branch."
    echo "11. Delete Branch: Remove a specified local branch (with confirmation and option for force delete)."
    echo "12. Create Tag: Create a lightweight or annotated tag for a specific commit."
    echo "13. Show Branch List: List all local branches with their last commit details."
    echo "14. Rebase Branch: Reapply commits from your current branch on top of another branch."
    echo "15. Show Remotes: List all configured remote repositories."
    echo "16. Show Tags: List all tags present in the repository."
    echo "17. Stash Management: Manage temporary changes with stash operations (save, apply, pop, drop, clear)."
    echo "18. Show Diff (Changes): Display the differences between your working directory, staged changes, and the last commit."
    echo "19. Reset Changes / Commits: Undo changes or commits using soft, mixed, or hard reset, or reset a specific file."
    echo "20. Revert a Commit: Create a new commit that undoes the changes from a previous commit."
    echo "21. Clean Untracked Files: Remove untracked files and directories from your working tree (DANGEROUS!)."
    echo "22. Manage .gitignore: Add entries to your .gitignore file to exclude files from Git tracking."
    echo "23. Help: Display this help message."
    echo "24. Exit: Terminate the script."
    echo -e "${NO_COLOR}"
    echo -e "${CYAN}Note: For most operations requiring a Git repository, ensure you are in the correct project directory.${NO_COLOR}"
    read -p "Press Enter to continue..."
}


# Cek ketersediaan Git sebelum melanjutkan
check_git

# Loop menu
while true; do
    show_menu
    read -r option

    case $option in
        1) clone_repository ;;
        2) create_and_switch_branch ;;
        3) switch_branch ;;
        4) commit_changes ;;
        5) push_changes ;;
        6) show_status ;;
        7) show_log ;;
        8) add_remote ;;
        9) update_repository ;;
        10) merge_branch ;;
        11) delete_branch ;;
        12) create_tag ;;
        13) show_branches ;;
        14) rebase_branch ;;
        15) show_remotes ;;
        16) show_tags ;;
        17) stash_management ;;
        18) show_diff ;;
        19) reset_changes ;;
        20) revert_commit ;;
        21) clean_untracked_files ;;
        22) manage_gitignore ;;
        23) show_help ;;
        24) echo -e "${GREEN}Exiting Git Manager. Semoga harimu menyenangkan, ciro!${NO_COLOR}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NO_COLOR}"; read -p "Press Enter to continue..." ;;
    esac
done
