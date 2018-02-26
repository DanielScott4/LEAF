<!-- form -->
<br />
<div class="printmainform" style="border-bottom: 0px; min-height: 64px">
    <div id="requestTitle"><!--{$title|strip_tags|escape}--> <!--{$subtype|strip_tags|escape}-->
    <!--{if $submitted == 0 || $is_admin}-->
        <img src="../libs/dynicons/?img=accessories-text-editor.svg&amp;w=16" style="cursor: pointer" alt="Edit Title" title="Edit Title" onclick="changeTitle()" />
    <!--{/if}-->

    <br /><span style="font-weight: normal; color: #686868; font-style: italic"><!--{$categoryText|strip_tags|escape}--></span>
    </div>
    <div id="requestInfo">
        <table>
            <tr>
                <td><!--{if $service != ''}-->Service<!--{else}-->&nbsp;<!--{/if}-->
                </td>
                <td><b><!--{$service|strip_tags|escape}--></b> 
                    <!--{if $submitted == 0}-->
                        <img src="../libs/dynicons/?img=accessories-text-editor.svg&amp;w=16" style="cursor: pointer" alt="Edit Service" title="Edit Service" onclick="changeService()" />
                    <!--{/if}-->
                </td>
            </tr>
            <tr>
                <td>Initiated by</td>
                <td><b><!--{$name|strip_tags|escape}--></b></td>
            </tr>
            <tr>
                <td>Submitted</td>
                <td><b><!--{if $date > 0}--><!--{$date|date_format:"%A, %B %e, %Y"}--><!--{else}-->Not submitted<!--{/if}--></b></td>
            </tr>
        </table>
    </div>
    <br class="noprint" style="clear: both"/>
</div>
<div class="tags<!--{if count($tags) == 0}--> noprint<!--{/if}-->" id="tags" style="border: 1px solid black; padding: 2px; text-align: right">
    <!--{include file="print_form_ajax_tags.tpl" tags=$tags}-->
    <!--{if count($tags) == 0}--><a href="#" onclick="getTags(<!--{$recordID|strip_tags|escape}-->);"></a><!--{/if}-->
</div>

<div class="printmainform">
    <!--{include file="print_subindicators.tpl" form=$form orgchartPath=$orgchartPath}-->
</div>


<br /><br />
