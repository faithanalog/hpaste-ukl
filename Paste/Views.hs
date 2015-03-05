{-# LANGUAGE QuasiQuotes #-}
module Paste.Views where
import           Text.Blaze.Html
import           Text.Blaze.Html.Renderer.Text (renderHtml)
import           Text.Highlighting.Kate
import           Data.Text.Lazy                (Text)
import           Text.Hamlet                   (shamlet)


formatCode :: String -> String -> Html
formatCode lang code = formatHtmlBlock opts (highlightAs lang code)
    where opts = defaultFormatOpts { numberLines = True }


codePage :: String -> String -> Text
codePage lang code = renderHtml [shamlet|
$doctype 5
<html>
    <head>
        #{pageHead}
    <body>
        #{pageMenu False}
        #{formatCode lang code}
|]


editPage :: Text -> Text
editPage textAreaInitial = renderHtml [shamlet|
$doctype 5
<html>
    <head>
        #{pageHead}
    <body>
        #{pageMenu True}
        <div id="prompt">&gt
        <textarea spellcheck="false" id="codeIn">
            #{textAreaInitial}
|]

pageHead :: Html
pageHead = [shamlet|
<link rel="stylesheet" href="/css/hk-solarized.css">
<link rel="stylesheet" href="/css/paste.css">
<link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css">
<script src="/js/paste.js">
<title>Paste</title>
|]


pageMenu :: Bool -> Html
pageMenu isEdit = [shamlet|
<div class="header">
    <div class="title">
        <h2>hpaste
        <h4>Dαsh
    <div class="menuButtons">
        <i class="#{btnClass isEdit}       fa fa-save fa-lg"        id="saveBtn"></i>
        <i class="button                   fa fa-plus fa-lg"        id="newBtn"></i>
        <i class="#{btnClass (not isEdit)} fa fa-pencil fa-lg"      id="editBtn"></i>
        <i class="#{btnClass (not isEdit)} fa fa-file-text fa-lg"   id="rawBtn"></i>
|]
    where btnClass x = if x then "button" else "buttonDisabled"
