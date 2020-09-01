{% if not (theme.duoshuo and theme.duoshuo.shortname) and not theme.duoshuo_shortname %}
  {% if theme.gitalk.enable %} 
      <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.css">
      <script src="https://unpkg.com/blueimp-md5@2.17.0/js/md5.js"></script>
      <script src="https://cdn.jsdelivr.net/npm/gitalk@1/dist/gitalk.min.js"></script>
      <script type="text/javascript">
          var gitalk = new Gitalk({
            clientID:  '{{theme.gitalk.clientID}}', 
            clientSecret: '{{theme.gitalk.clientSecret}}',
            id: md5(location.pathname),
            repo: '{{theme.gitalk.repo}}', 
            owner: '{{theme.gitalk.owner}}', 
            admin: ['{{theme.gitalk.admin}}'], 
            distractionFreeMode: {{theme.gitalk.distractionFreeMode}},
            language: '{{theme.gitalk.language}}',
            createIssueManually: {{theme.gitalk.createIssueManually}}
          })
          gitalk.render('gitalk-container')
      </script>
  {% endif %}
{% endif %}
