"""Tests for post-generation hook functionality."""

from pathlib import Path


def test_post_gen_hook_exists():
    """Test that the post-generation hook file exists.

    This test verifies that the post_gen_project.sh hook file exists
    in the hooks directory.
    """
    hook_file = Path(__file__).parent.parent / "hooks" / "post_gen_project.sh"
    assert hook_file.exists(), "Post-generation hook should exist"


def test_post_gen_hook_contains_env_creation():
    """Test that the post-generation hook contains .env file creation logic.

    This test verifies that the post_gen_project.sh hook contains the
    necessary code to create a .env file.
    """
    hook_file = Path(__file__).parent.parent / "hooks" / "post_gen_project.sh"
    hook_content = hook_file.read_text()

    # Check for .env file creation
    assert "# Create .env file" in hook_content, (
        "Hook should contain .env file creation comment"
    )
    assert ".env" in hook_content, "Hook should reference .env file"
    assert "Environment variables for" in hook_content, (
        "Hook should create environment variables file"
    )


def test_post_gen_hook_contains_git_setup():
    """Test that the post-generation hook contains git setup logic.

    This test verifies that the post_gen_project.sh hook contains the
    necessary code to initialize a git repository.
    """
    hook_file = Path(__file__).parent.parent / "hooks" / "post_gen_project.sh"
    hook_content = hook_file.read_text()

    # Check for git initialization
    assert "git init" in hook_content, "Hook should initialize git repository"
    assert "git add" in hook_content, "Hook should add files to git"
    assert "git commit" in hook_content, "Hook should make initial commit"


def test_post_gen_hook_contains_pixi_setup():
    """Test that the post-generation hook contains pixi setup logic.

    This test verifies that the post_gen_project.sh hook contains the
    necessary code to install pixi environment.
    """
    hook_file = Path(__file__).parent.parent / "hooks" / "post_gen_project.sh"
    hook_content = hook_file.read_text()

    # Check for pixi installation
    assert "pixi install" in hook_content, "Hook should install pixi environment"
    assert "pixi run" in hook_content, "Hook should run pixi commands"


def test_post_gen_hook_contains_github_setup():
    """Test that the post-generation hook contains GitHub setup logic.

    This test verifies that the post_gen_project.sh hook contains the
    necessary code to set up GitHub repository.
    """
    hook_file = Path(__file__).parent.parent / "hooks" / "post_gen_project.sh"
    hook_content = hook_file.read_text()

    # Check for GitHub CLI usage
    assert "gh repo create" in hook_content, "Hook should create GitHub repository"
    assert "gh auth" in hook_content, "Hook should check GitHub authentication"
