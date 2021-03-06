styleTemplate = require './style-template'
path = require 'path'

fs = null
less = null
mpeGithubSyntax = null

# cb(error, css) is optional
loadPreviewTheme = (previewTheme, changePreview=false, cb)->
  previewThemeElement = document.getElementById('markdown-preview-enhanced-preview-theme')
  return cb?(false, previewThemeElement.innerHTML) if previewThemeElement?.getAttribute('data-preview-theme') == previewTheme and previewThemeElement?.innerHTML.length # same preview theme, no need to change.

  if !previewThemeElement
    previewThemeElement = document.createElement('style')
    previewThemeElement.id = 'markdown-preview-enhanced-preview-theme'
    previewThemeElement.setAttribute('for', 'markdown-preview-enhanced')
    head = document.getElementsByTagName('head')[0]
    atomStyles = document.getElementsByTagName('atom-styles')[0]
    head.insertBefore(previewThemeElement, atomStyles)
  previewThemeElement.setAttribute 'data-preview-theme', previewTheme if changePreview

  fs ?= require 'fs'
  less ?= require 'less'
  themes = atom.themes.getLoadedThemes()

  if previewTheme == 'mpe-github-syntax'
    mpeGithubSyntax ?= require './mpe-github-syntax-template.coffee'
    data = (mpeGithubSyntax + styleTemplate).replace('@import "styles/syntax-variables.less";', '')
    return less.render data, {}, (error, output)->
      return cb?(error) if error
      css = output.css.replace(/[^\.]atom-text-editor/g, '.markdown-preview-enhanced pre')
                .replace(/:host/g, '.markdown-preview-enhanced .host')
                .replace(/\.syntax\-\-/g, '.mpe-syntax--')

      previewThemeElement.innerHTML = css if changePreview
      return cb?(false, css)

  # traverse all themes
  for theme in themes
    if theme.name == previewTheme # found the theme that match previewTheme
      themePath = theme.path
      indexLessPath = path.resolve(themePath, './index.less')
      syntaxVariablesFile = path.resolve(themePath, './styles/syntax-variables.less')

      # compile less to css
      fs.readFile indexLessPath, {encoding: 'utf-8'}, (error, data)->
        return cb?(error) if error

        # replace css to css.less; otherwise it will cause error.
        data = (data or '').replace(/\/css("|')\;/g, '\/css.less$1;')
        data += styleTemplate

        less.render data, {paths: [themePath, path.resolve(themePath, 'styles')]}, (error, output)->
          return cb?(error) if error
          css = output.css.replace(/[^\.]atom-text-editor/g, '.markdown-preview-enhanced pre')
                    .replace(/:host/g, '.markdown-preview-enhanced .host')
                    .replace(/\.syntax\-\-/g, '.mpe-syntax--')

          previewThemeElement.innerHTML = css if changePreview
          return cb?(false, css)
      return

  return cb?('theme not found') # error theme not found

module.exports = {
  loadPreviewTheme
}
